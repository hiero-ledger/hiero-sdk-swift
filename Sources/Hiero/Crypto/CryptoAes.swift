// SPDX-License-Identifier: Apache-2.0

import CryptoKit
import Foundation

#if canImport(CommonCrypto)
    import CommonCrypto

    enum CryptoError: Error {
        case invalidInput
    }

    enum CryptoAES {
        static func encrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
            return try crypt(data: data, key: key, iv: iv, operation: kCCEncrypt)
        }

        static func decrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
            return try crypt(data: data, key: key, iv: iv, operation: kCCDecrypt)
        }

        private static func crypt(data: Data, key: Data, iv: Data, operation: Int) throws -> Data {
            var outLength = 0
            var outData = Data(count: data.count + kCCBlockSizeAES128)
            // Capture length before entering the mutating closure to avoid overlapping access.
            let outCapacity = outData.count

            let status = outData.withUnsafeMutableBytes { outBytes in
                data.withUnsafeBytes { inBytes in
                    key.withUnsafeBytes { keyBytes in
                        iv.withUnsafeBytes { ivBytes in
                            let outPtr = outBytes.baseAddress
                            let inPtr = inBytes.baseAddress
                            let keyPtr = keyBytes.baseAddress
                            let ivPtr = ivBytes.baseAddress
                            guard let outPtr, let inPtr, let keyPtr, let ivPtr else {
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
    }

#else
    import CryptoSwift  // Linux path

    enum CryptoError: Error {
        case invalidInput
    }

    enum CryptoAES {
        static func encrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7)
            let cipher = try aes.encrypt(data.bytes)
            return Data(cipher)
        }

        static func decrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7)
            let plain = try aes.decrypt(data.bytes)
            return Data(plain)
        }
    }

    extension Data {
        fileprivate var bytes: [UInt8] { Array(self) }
    }

#endif

extension Crypto {
    internal enum AesError: Error {
        case bufferTooSmall(available: Int, needed: Int)
        case alignment
        case decode
        case other(Int32)
    }

    internal enum Aes {
    }
}

extension Crypto.Aes {
    internal static func aes128CbcPadDecrypt(key: Data, iv: Data, message: Data) throws -> Data {
        precondition(key.count == 16, "bug: key size \(key.count) incorrect for algorithm")
        precondition(iv.count == 16, "bug: iv size incorrect for algorithm")

        // we have to do the very fun dance of trying a second time if the buffer is too small
        do {
            return try aes128CbcPadDecryptOnce(key: key, iv: iv, message: message, outputCapacity: message.count)
        } catch Crypto.AesError.bufferTooSmall(available: _, let needed) {
            return try aes128CbcPadDecryptOnce(key: key, iv: iv, message: message, outputCapacity: needed)
        }
    }

    private static func aes128CbcPadDecryptOnce(
        key: Data,
        iv: Data,
        message: Data,
        outputCapacity: Int
    ) throws -> Data {
        var output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: message.count)
        output.initialize(repeating: 0)

        defer {
            output.deallocate()
        }

        let data = try aes128CbcPadDecryptInner(
            key: key,
            iv: iv,
            message: message,
            output: &output
        )

        return data
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
                    var dataOutMoved: Int = 0

                    let status = CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        key.baseAddress,
                        key.count,
                        iv.baseAddress,
                        message.baseAddress,
                        message.count,
                        output.baseAddress,
                        output.count,
                        &dataOutMoved
                    )

                    switch Int(status) {
                    case kCCSuccess:
                        let tmp = output[..<dataOutMoved]
                        return Data(tmp)

                    case kCCBufferTooSmall:
                        throw Crypto.AesError.bufferTooSmall(available: output.count, needed: dataOutMoved)
                    case kCCAlignmentError: throw Crypto.AesError.alignment
                    case kCCDecodeError: throw Crypto.AesError.decode
                    default: throw Crypto.AesError.other(status)
                    }
                }
            }
        }
    }
}
