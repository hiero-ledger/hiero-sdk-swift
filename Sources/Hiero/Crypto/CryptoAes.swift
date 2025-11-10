// SPDX-License-Identifier: Apache-2.0

import Foundation

#if canImport(CommonCrypto)
    import CommonCrypto
#else
    import CryptoSwift
#endif

// MARK: - Cross-platform AES helpers (standalone)

enum CryptoError: Error {
    case invalidInput
}

/// Cross-platform AES-CBC implementation.
/// - Apple platforms: CommonCrypto
/// - Linux: CryptoSwift
enum CryptoAES {
    static func encrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
        #if canImport(CommonCrypto)
            return try cryptCC(data: data, key: key, iv: iv, operation: kCCEncrypt)
        #else
            let aes = try AES(key: Array(key), blockMode: CBC(iv: Array(iv)), padding: .pkcs7)
            return Data(try aes.encrypt(Array(data)))
        #endif
    }

    static func decrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
        #if canImport(CommonCrypto)
            return try cryptCC(data: data, key: key, iv: iv, operation: kCCDecrypt)
        #else
            let aes = try AES(key: Array(key), blockMode: CBC(iv: Array(iv)), padding: .pkcs7)
            return Data(try aes.decrypt(Array(data)))
        #endif
    }

    static func aes128CbcPadDecrypt(key: Data, iv: Data, message: Data) throws -> Data {
        precondition(key.count == 16, "bug: key size \(key.count) incorrect for AES-128")
        precondition(iv.count == 16, "bug: iv size incorrect for AES-128")

        return try decrypt(message, key: key, iv: iv)
    }

    #if canImport(CommonCrypto)
        private static func cryptCC(data: Data, key: Data, iv: Data, operation: Int) throws -> Data {
            var outLength = 0
            var outData = Data(count: data.count + kCCBlockSizeAES128)
            let outCapacity = outData.count  // capture before mutating closure (avoid overlapping access)

            let status = outData.withUnsafeMutableBytes { outBytes in
                data.withUnsafeBytes { inBytes in
                    key.withUnsafeBytes { keyBytes in
                        iv.withUnsafeBytes { ivBytes in
                            guard
                                let outPtr = outBytes.baseAddress,
                                let inPtr = inBytes.baseAddress,
                                let keyPtr = keyBytes.baseAddress,
                                let ivPtr = ivBytes.baseAddress
                            else {
                                return CCCryptorStatus(kCCMemoryFailure)
                            }

                            return CCCrypt(
                                CCOperation(operation),
                                CCAlgorithm(kCCAlgorithmAES),
                                CCOptions(kCCOptionPKCS7Padding),
                                keyPtr, key.count,
                                ivPtr,
                                inPtr, data.count,
                                outPtr, outCapacity,
                                &outLength
                            )
                        }
                    }
                }
            }

            guard status == kCCSuccess else { throw CryptoError.invalidInput }
            outData.removeSubrange(outLength..<outData.count)
            return outData
        }
    #endif
}

// MARK: - Add `Aes` into your existing `Crypto` namespace

/// Extend the project's existing `CryptoNamespace` with AES helpers used by PBES2, etc.
/// This avoids creating a new top-level `enum Crypto` (which caused ambiguity), while
/// letting existing call sites keep using `CryptoNamespace.Aes.aes128CbcPadDecrypt(...)`.
extension CryptoNamespace {
    internal enum AesError: Error {
        case bufferTooSmall(available: Int, needed: Int)
        case alignment
        case decode
        case other(Int32)
    }

    internal enum Aes {
        /// AES-128-CBC with PKCS#7 padding decrypt helper.
        /// - Note: On Apple platforms uses CommonCrypto. On Linux uses CryptoSwift.
        internal static func aes128CbcPadDecrypt(key: Data, iv: Data, message: Data) throws -> Data {
            precondition(key.count == 16, "bug: key size \(key.count) incorrect for AES-128")
            precondition(iv.count == 16, "bug: iv size incorrect for AES-128")

            #if canImport(CommonCrypto)
                // Try once with message.count, retry if CommonCrypto reports a larger needed size.
                do {
                    return try aes128CbcPadDecryptOnce(
                        key: key, iv: iv, message: message, outputCapacity: message.count)
                } catch AesError.bufferTooSmall(_, let needed) {
                    return try aes128CbcPadDecryptOnce(key: key, iv: iv, message: message, outputCapacity: needed)
                }
            #else
                let aes = try AES(key: Array(key), blockMode: CBC(iv: Array(iv)), padding: .pkcs7)
                return Data(try aes.decrypt(Array(message)))
            #endif
        }

        #if canImport(CommonCrypto)
            private static func aes128CbcPadDecryptOnce(
                key: Data,
                iv: Data,
                message: Data,
                outputCapacity: Int
            ) throws -> Data {
                var output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: outputCapacity)
                output.initialize(repeating: 0)
                defer { output.deallocate() }

                return try aes128CbcPadDecryptInner(
                    key: key,
                    iv: iv,
                    message: message,
                    output: &output
                )
            }

            private static func aes128CbcPadDecryptInner(
                key: Data,
                iv: Data,
                message: Data,
                output: inout UnsafeMutableBufferPointer<UInt8>
            ) throws -> Data {
                try key.withUnsafeBytes { key in
                    try iv.withUnsafeBytes { iv in
                        try message.withUnsafeBytes { message in
                            var dataOutMoved = 0

                            let status = CCCrypt(
                                CCOperation(kCCDecrypt),
                                CCAlgorithm(kCCAlgorithmAES),
                                CCOptions(kCCOptionPKCS7Padding),
                                key.baseAddress, key.count,
                                iv.baseAddress,
                                message.baseAddress, message.count,
                                output.baseAddress, output.count,
                                &dataOutMoved
                            )

                            switch Int(status) {
                            case kCCSuccess:
                                return Data(output[..<dataOutMoved])
                            case kCCBufferTooSmall:
                                throw AesError.bufferTooSmall(available: output.count, needed: dataOutMoved)
                            case kCCAlignmentError:
                                throw AesError.alignment
                            case kCCDecodeError:
                                throw AesError.decode
                            default:
                                throw AesError.other(status)
                            }
                        }
                    }
                }
            }
        #endif
    }
}
