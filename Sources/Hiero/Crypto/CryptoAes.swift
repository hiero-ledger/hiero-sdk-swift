// SPDX-License-Identifier: Apache-2.0

import Foundation

#if canImport(CommonCrypto)
    import CommonCrypto
#else
    import CryptoSwift
#endif

// MARK: - AES Encryption/Decryption
//
// Platform-specific AES-CBC implementation:
// - Apple platforms: Uses CommonCrypto (C library bundled with the OS)
// - Linux: Uses CryptoSwift (pure Swift implementation)
//
// Both provide AES-128-CBC with PKCS#7 padding for encrypted private key support.

/// Errors that can occur during AES encryption/decryption operations.
internal enum CryptoError: Error {
    case invalidInput
}

/// AES encryption and decryption using CBC mode with PKCS#7 padding.
///
/// This enum provides platform-specific implementations:
/// - **Apple platforms**: Uses CommonCrypto for hardware-accelerated encryption
/// - **Linux**: Uses CryptoSwift for pure Swift encryption
///
/// Currently only supports AES-128-CBC, which is used for PKCS#8 encrypted private keys.
internal enum CryptoAES {
    /// Encrypt data using AES-CBC with PKCS#7 padding.
    ///
    /// - Parameters:
    ///   - data: The plaintext data to encrypt.
    ///   - key: The encryption key (16 bytes for AES-128).
    ///   - iv: The initialization vector (16 bytes).
    /// - Returns: The encrypted ciphertext.
    /// - Throws: `CryptoError.invalidInput` if encryption fails.
    internal static func encrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
        #if canImport(CommonCrypto)
            return try cryptCC(data: data, key: key, iv: iv, operation: kCCEncrypt)
        #else
            let aes = try AES(key: Array(key), blockMode: CBC(iv: Array(iv)), padding: .pkcs7)
            return Data(try aes.encrypt(Array(data)))
        #endif
    }

    /// Decrypt data using AES-CBC with PKCS#7 padding.
    ///
    /// - Parameters:
    ///   - data: The ciphertext data to decrypt.
    ///   - key: The decryption key (16 bytes for AES-128).
    ///   - iv: The initialization vector (16 bytes).
    /// - Returns: The decrypted plaintext.
    /// - Throws: `CryptoError.invalidInput` if decryption fails.
    internal static func decrypt(_ data: Data, key: Data, iv: Data) throws -> Data {
        #if canImport(CommonCrypto)
            return try cryptCC(data: data, key: key, iv: iv, operation: kCCDecrypt)
        #else
            let aes = try AES(key: Array(key), blockMode: CBC(iv: Array(iv)), padding: .pkcs7)
            return Data(try aes.decrypt(Array(data)))
        #endif
    }

    /// Decrypt data using AES-128-CBC with PKCS#7 padding.
    ///
    /// This is a convenience method for AES-128 specifically, used by PKCS#5 PBES2.
    ///
    /// - Parameters:
    ///   - key: The 16-byte decryption key.
    ///   - iv: The 16-byte initialization vector.
    ///   - message: The ciphertext to decrypt.
    /// - Returns: The decrypted plaintext.
    /// - Throws: `CryptoError.invalidInput` if decryption fails.
    internal static func aes128CbcPadDecrypt(key: Data, iv: Data, message: Data) throws -> Data {
        precondition(key.count == 16, "bug: key size \(key.count) incorrect for AES-128")
        precondition(iv.count == 16, "bug: iv size incorrect for AES-128")

        return try decrypt(message, key: key, iv: iv)
    }

    #if canImport(CommonCrypto)
        /// Internal CommonCrypto-based encryption/decryption implementation.
        ///
        /// - Parameters:
        ///   - data: Input data (plaintext or ciphertext).
        ///   - key: Encryption/decryption key.
        ///   - iv: Initialization vector.
        ///   - operation: Either `kCCEncrypt` or `kCCDecrypt`.
        /// - Returns: Output data (ciphertext or plaintext).
        /// - Throws: `CryptoError.invalidInput` if the operation fails.
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

// MARK: - CryptoNamespace Extension
//
// Integrate AES functionality into the SDK's internal CryptoNamespace.

extension CryptoNamespace {
    /// Errors that can occur during AES operations within the CryptoNamespace.
    internal enum AesError: Error {
        case bufferTooSmall(available: Int, needed: Int)
        case alignment
        case decode
        case other(Int32)
    }

    /// AES encryption helpers for use with PKCS#5 PBES2 encrypted private keys.
    internal enum Aes {
        /// Decrypt data using AES-128-CBC with PKCS#7 padding.
        ///
        /// This method is used by the PKCS#5 PBES2 implementation to decrypt encrypted private keys.
        ///
        /// - Parameters:
        ///   - key: The 16-byte decryption key (derived via PBKDF2).
        ///   - iv: The 16-byte initialization vector.
        ///   - message: The encrypted private key data.
        /// - Returns: The decrypted private key data.
        /// - Throws: `AesError` if decryption fails.
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
            /// Attempt AES-128-CBC decryption with a specific output buffer size.
            ///
            /// - Parameters:
            ///   - key: The 16-byte decryption key.
            ///   - iv: The 16-byte initialization vector.
            ///   - message: The ciphertext to decrypt.
            ///   - outputCapacity: The size of the output buffer to allocate.
            /// - Returns: The decrypted plaintext.
            /// - Throws: `AesError.bufferTooSmall` if the buffer is too small (with the required size).
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

            /// Core CommonCrypto-based AES-128-CBC decryption implementation.
            ///
            /// - Parameters:
            ///   - key: The 16-byte decryption key.
            ///   - iv: The 16-byte initialization vector.
            ///   - message: The ciphertext to decrypt.
            ///   - output: The output buffer to write the plaintext to.
            /// - Returns: The decrypted plaintext.
            /// - Throws: `AesError` variants based on the CCCrypt status code.
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
