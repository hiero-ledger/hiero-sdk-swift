// SPDX-License-Identifier: Apache-2.0

// MARK: - Crypto Namespace
//
// This file defines the `CryptoNamespace` enum, which serves as a namespace
// for organizing cryptographic functionality used throughout the Hiero SDK.
//
// The namespace pattern avoids polluting the global namespace with generic names
// like "Aes" or "Hmac", and provides a clear organizational structure for
// crypto-related code.
//
// Extensions in other files add functionality to this namespace:
// - CryptoAes.swift: AES encryption/decryption
// - CryptoSha2.swift: SHA-256, SHA-384, SHA-512
// - CryptoSha3.swift: Keccak-256
// - Crypto+k256Digest.swift: secp256k1 digest types

/// Namespace for cryptographic primitives used by the Hiero SDK.
///
/// This enum is never instantiated - it exists solely as a namespace to
/// organize cryptographic functionality.
internal enum CryptoNamespace {}

// MARK: - HMAC Algorithm Selection

extension CryptoNamespace {
    /// HMAC (Hash-based Message Authentication Code) algorithm variants.
    ///
    /// Specifies which hash function to use with HMAC for key derivation
    /// and message authentication.
    internal enum Hmac {
        /// HMAC using a SHA-2 family hash function.
        case sha2(CryptoNamespace.Sha2)
    }
}
