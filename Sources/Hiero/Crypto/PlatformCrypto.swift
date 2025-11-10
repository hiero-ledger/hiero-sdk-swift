// SPDX-License-Identifier: Apache-2.0

import Foundation

#if canImport(Crypto)
    import Crypto
#elseif canImport(CryptoKit)
    import CryptoKit
#endif

// MARK: - Ed25519 Key Types
//
// These types provide a unified interface for Ed25519 cryptography across platforms:
// - Apple platforms: Uses CryptoKit (bundled with the OS)
// - Linux: Uses Swift Crypto (open-source implementation)
//
// Both implementations provide identical APIs, so these wrappers simply
// delegate to the appropriate underlying library based on platform.

/// Ed25519 private key for signing operations.
///
/// This type abstracts over platform-specific Ed25519 implementations:
/// - Apple platforms use `CryptoKit.Curve25519.Signing.PrivateKey`
/// - Linux uses `Crypto.Curve25519.Signing.PrivateKey` from Swift Crypto
internal struct Ed25519PrivateKey {
    #if canImport(Crypto)
        private let key: Curve25519.Signing.PrivateKey
    #else
        private let key: CryptoKit.Curve25519.Signing.PrivateKey
    #endif

    /// Generate a new random Ed25519 private key.
    internal init() {
        #if canImport(Crypto)
            self.key = Curve25519.Signing.PrivateKey()
        #else
            self.key = CryptoKit.Curve25519.Signing.PrivateKey()
        #endif
    }

    /// Create an Ed25519 private key from its 32-byte raw representation.
    internal init(rawRepresentation: Data) throws {
        #if canImport(Crypto)
            self.key = try Curve25519.Signing.PrivateKey(rawRepresentation: rawRepresentation)
        #else
            self.key = try CryptoKit.Curve25519.Signing.PrivateKey(rawRepresentation: rawRepresentation)
        #endif
    }

    /// The 32-byte raw representation of the private key.
    internal var rawRepresentation: Data {
        key.rawRepresentation
    }

    /// The corresponding Ed25519 public key for this private key.
    internal var publicKey: Ed25519PublicKey {
        #if canImport(Crypto)
            return Ed25519PublicKey(key: key.publicKey)
        #else
            return Ed25519PublicKey(key: key.publicKey)
        #endif
    }

    /// Generate an Ed25519 signature for the given data.
    ///
    /// - Parameter data: The data to sign.
    /// - Returns: The 64-byte signature.
    internal func signature(for data: Data) throws -> Data {
        #if canImport(Crypto)
            return try key.signature(for: data)
        #else
            return try key.signature(for: data)
        #endif
    }
}

/// Ed25519 public key for signature verification.
///
/// This type abstracts over platform-specific Ed25519 implementations:
/// - Apple platforms use `CryptoKit.Curve25519.Signing.PublicKey`
/// - Linux uses `Crypto.Curve25519.Signing.PublicKey` from Swift Crypto
internal struct Ed25519PublicKey {
    #if canImport(Crypto)
        private let key: Curve25519.Signing.PublicKey
    #else
        private let key: CryptoKit.Curve25519.Signing.PublicKey
    #endif

    /// Create an Ed25519 public key from its 32-byte raw representation.
    internal init(rawRepresentation: Data) throws {
        #if canImport(Crypto)
            self.key = try Curve25519.Signing.PublicKey(rawRepresentation: rawRepresentation)
        #else
            self.key = try CryptoKit.Curve25519.Signing.PublicKey(rawRepresentation: rawRepresentation)
        #endif
    }

    /// Create an Ed25519 public key from a platform-specific key instance.
    /// Used internally when deriving a public key from a private key.
    internal init(key: Any) {
        #if canImport(Crypto)
            self.key = key as! Curve25519.Signing.PublicKey
        #else
            self.key = key as! CryptoKit.Curve25519.Signing.PublicKey
        #endif
    }

    /// The 32-byte raw representation of the public key.
    internal var rawRepresentation: Data {
        key.rawRepresentation
    }

    /// Verify an Ed25519 signature for the given data.
    ///
    /// - Parameters:
    ///   - signature: The 64-byte signature to verify.
    ///   - data: The data that was signed.
    /// - Returns: `true` if the signature is valid, `false` otherwise.
    internal func isValidSignature(_ signature: Data, for data: Data) -> Bool {
        #if canImport(Crypto)
            return key.isValidSignature(signature, for: data)
        #else
            return key.isValidSignature(signature, for: data)
        #endif
    }
}

// MARK: - MD5 Hasher
//
// Note: MD5 is cryptographically broken and should not be used for security purposes.
// This is provided only for compatibility with legacy systems.

/// Incremental MD5 hasher for computing MD5 digests.
///
/// **Warning:** MD5 is cryptographically broken. Use only for non-security purposes
/// such as checksums in legacy protocols.
internal struct MD5Hasher {
    #if canImport(Crypto)
        private var md5: Insecure.MD5
    #else
        private var md5: CryptoKit.Insecure.MD5
    #endif

    /// Create a new MD5 hasher instance.
    internal init() {
        #if canImport(Crypto)
            self.md5 = Insecure.MD5()
        #else
            self.md5 = CryptoKit.Insecure.MD5()
        #endif
    }

    /// Add data to the hash computation.
    ///
    /// - Parameter data: Data to include in the hash.
    internal mutating func update(data: Data) {
        #if canImport(Crypto)
            md5.update(data: data)
        #else
            md5.update(data: data)
        #endif
    }

    /// Complete the hash computation and return the digest.
    ///
    /// - Returns: The 16-byte MD5 digest.
    internal func finalize() -> Data {
        #if canImport(Crypto)
            return Data(md5.finalize())
        #else
            return Data(md5.finalize())
        #endif
    }
}

// MARK: - Type Aliases for Platform-Specific Crypto Types
//
// These aliases provide a unified interface to cryptographic types across platforms.
// They resolve to either Swift Crypto (Linux) or CryptoKit (Apple) based on availability.
#if canImport(Crypto)
    internal typealias SHA512Digest = SHA512
    internal typealias HMAC<H: HashFunction> = Crypto.HMAC<H>
    internal typealias SymmetricKey = Crypto.SymmetricKey

    // Direct type aliases for use throughout the SDK
    internal typealias Curve25519 = Crypto.Curve25519
    internal typealias P256 = Crypto.P256
#else
    internal typealias SHA512Digest = CryptoKit.SHA512
    internal typealias HMAC<H: HashFunction> = CryptoKit.HMAC<H>
    internal typealias SymmetricKey = CryptoKit.SymmetricKey

    // Direct type aliases for use throughout the SDK
    internal typealias Curve25519 = CryptoKit.Curve25519
    internal typealias P256 = CryptoKit.P256
#endif
