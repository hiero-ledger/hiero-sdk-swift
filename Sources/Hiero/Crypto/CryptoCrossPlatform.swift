// SPDX-License-Identifier: Apache-2.0

import Foundation

#if canImport(Crypto)
    import Crypto
#elseif canImport(CryptoKit)
    import CryptoKit
#endif

// MARK: - Cross-platform crypto types

/// Cross-platform Ed25519 private key
public struct CrossPlatformEd25519PrivateKey {
    #if canImport(Crypto)
        private let key: Curve25519.Signing.PrivateKey
    #else
        private let key: CryptoKit.Curve25519.Signing.PrivateKey
    #endif
    
    public init() {
        #if canImport(Crypto)
            self.key = Curve25519.Signing.PrivateKey()
        #else
            self.key = CryptoKit.Curve25519.Signing.PrivateKey()
        #endif
    }
    
    public init(rawRepresentation: Data) throws {
        #if canImport(Crypto)
            self.key = try Curve25519.Signing.PrivateKey(rawRepresentation: rawRepresentation)
        #else
            self.key = try CryptoKit.Curve25519.Signing.PrivateKey(rawRepresentation: rawRepresentation)
        #endif
    }
    
    public var rawRepresentation: Data {
        key.rawRepresentation
    }
    
    public var publicKey: CrossPlatformEd25519PublicKey {
        #if canImport(Crypto)
            return CrossPlatformEd25519PublicKey(key: key.publicKey)
        #else
            return CrossPlatformEd25519PublicKey(key: key.publicKey)
        #endif
    }
    
    public func signature(for data: Data) throws -> Data {
        #if canImport(Crypto)
            return try key.signature(for: data)
        #else
            return try key.signature(for: data)
        #endif
    }
}

/// Cross-platform Ed25519 public key
public struct CrossPlatformEd25519PublicKey {
    #if canImport(Crypto)
        private let key: Curve25519.Signing.PublicKey
    #else
        private let key: CryptoKit.Curve25519.Signing.PublicKey
    #endif
    
    public init(rawRepresentation: Data) throws {
        #if canImport(Crypto)
            self.key = try Curve25519.Signing.PublicKey(rawRepresentation: rawRepresentation)
        #else
            self.key = try CryptoKit.Curve25519.Signing.PublicKey(rawRepresentation: rawRepresentation)
        #endif
    }
    
    internal init(key: Any) {
        #if canImport(Crypto)
            self.key = key as! Curve25519.Signing.PublicKey
        #else
            self.key = key as! CryptoKit.Curve25519.Signing.PublicKey
        #endif
    }
    
    public var rawRepresentation: Data {
        key.rawRepresentation
    }
    
    public func isValidSignature(_ signature: Data, for data: Data) -> Bool {
        #if canImport(Crypto)
            return key.isValidSignature(signature, for: data)
        #else
            return key.isValidSignature(signature, for: data)
        #endif
    }
}

/// Cross-platform MD5
public struct CrossPlatformMD5 {
    #if canImport(Crypto)
        private var md5: Insecure.MD5
    #else
        private var md5: CryptoKit.Insecure.MD5
    #endif
    
    public init() {
        #if canImport(Crypto)
            self.md5 = Insecure.MD5()
        #else
            self.md5 = CryptoKit.Insecure.MD5()
        #endif
    }
    
    public mutating func update(data: Data) {
        #if canImport(Crypto)
            md5.update(data: data)
        #else
            md5.update(data: data)
        #endif
    }
    
    public func finalize() -> Data {
        #if canImport(Crypto)
            return Data(md5.finalize())
        #else
            return Data(md5.finalize())
        #endif
    }
}

// MARK: - Hash function types

#if canImport(Crypto)
    public typealias CrossPlatformSHA512 = SHA512
#else
    public typealias CrossPlatformSHA512 = CryptoKit.SHA512
#endif

// MARK: - Cross-platform Curve25519 types for compatibility

#if canImport(Crypto)
    public typealias Curve25519 = Crypto.Curve25519
#else
    public typealias Curve25519 = CryptoKit.Curve25519
#endif

// MARK: - Cross-platform HMAC and SymmetricKey for compatibility

#if canImport(Crypto)
    public typealias HMAC<H: HashFunction> = Crypto.HMAC<H>
    public typealias SymmetricKey = Crypto.SymmetricKey
#else
    public typealias HMAC<H: HashFunction> = CryptoKit.HMAC<H>
    public typealias SymmetricKey = CryptoKit.SymmetricKey
#endif

// MARK: - Cross-platform P256 for compatibility

#if canImport(Crypto)
    public typealias P256 = Crypto.P256
#else
    public typealias P256 = CryptoKit.P256
#endif
