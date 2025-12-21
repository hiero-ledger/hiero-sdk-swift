// SPDX-License-Identifier: Apache-2.0

/// Private key implementation for the Hiero SDK.
///
/// This file provides:
/// - `PrivateKey` - Ed25519 or ECDSA secp256k1 private key
/// - `ChainCode` - HD wallet chain code for key derivation
/// - `MD5Hasher` - Legacy hasher for encrypted PEM files
///
/// Supported key types:
/// - **Ed25519**: Used for EdDSA signatures (default)
/// - **ECDSA secp256k1**: Used for Ethereum-compatible signatures

import Foundation
import NumberKit
import SwiftASN1
import secp256k1

// MARK: - PrivateKey

/// A private key for a Hiero network.
///
/// Supports two key types:
/// - **Ed25519**: The default key type, used for EdDSA signatures
/// - **ECDSA secp256k1**: Used for Ethereum-compatible signatures
///
/// ## Generating Keys
/// ```swift
/// let ed25519Key = PrivateKey.generateEd25519()
/// let ecdsaKey = PrivateKey.generateEcdsa()
/// ```
///
/// ## Parsing Keys
/// ```swift
/// let key = try PrivateKey.fromString("302e020100300506...")
/// let pemKey = try PrivateKey.fromPem(pemString)
/// ```
///
/// ## Signing
/// ```swift
/// let signature = key.sign(message)
/// ```
public struct PrivateKey: LosslessStringConvertible, ExpressibleByStringLiteral, CustomStringConvertible,
    CustomDebugStringConvertible
{
    // MARK: Private Properties

    /// The secp256k1 curve order (for ECDSA key derivation).
    // swiftlint:disable:next force_unwrapping
    private let secp256k1Order = BigInt(
        unsignedBEBytes: Data(hexEncoded: "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")!)

    /// Internal representation for `Sendable` conformance.
    ///
    /// Stores raw key bytes to enable reconstruction on demand,
    /// since the underlying crypto key types are not `Sendable`.
    private let guts: Repr

    /// Reconstructed key (computed on access).
    private var kind: Kind {
        guts.kind
    }

    /// The HD wallet chain code, if this key supports derivation.
    public let chainCode: ChainCode?

    // MARK: Private Types

    /// Sendable-compatible representation of the key.
    fileprivate enum Repr: CustomDebugStringConvertible {
        /// Ed25519 key stored as raw bytes.
        case ed25519(Data)
        /// ECDSA secp256k1 key stored as raw bytes.
        case ecdsa(Data)

        /// A debug description that redacts the key material.
        fileprivate var debugDescription: String {
            switch self {
            case .ed25519: return "ed25519([redacted])"
            case .ecdsa: return "ecdsa([redacted])"
            }
        }

        /// Creates a representation from the actual key type.
        fileprivate init(kind: PrivateKey.Kind) {
            switch kind {
            case .ecdsa(let key): self = .ecdsa(key.dataRepresentation)
            case .ed25519(let key): self = .ed25519(key.rawRepresentation)
            }
        }

        /// Reconstructs the actual key type from the stored bytes.
        fileprivate var kind: PrivateKey.Kind {
            // swiftlint:disable force_try
            switch self {
            case .ecdsa(let key): return .ecdsa(try! .init(dataRepresentation: key))
            case .ed25519(let key): return .ed25519(try! .init(rawRepresentation: key))
            }
            // swiftlint:enable force_try
        }
    }

    /// The actual key type.
    fileprivate enum Kind {
        /// Ed25519 key for EdDSA signatures.
        case ed25519(Curve25519.Signing.PrivateKey)
        /// ECDSA secp256k1 key for Ethereum-compatible signatures.
        case ecdsa(secp256k1.Signing.PrivateKey)
    }

    // MARK: Initializers (Private)

    /// Creates a private key with the specified kind and optional chain code.
    private init(kind: Kind, chainCode: Data? = nil) {
        self.guts = .init(kind: kind)
        self.chainCode = chainCode.map(ChainCode.init(data:))
    }

    /// Decodes hex-encoded bytes, stripping optional "0x" prefix.
    private static func decodeBytes<S: StringProtocol>(_ description: S) throws -> Data {
        let description = description.stripPrefix("0x") ?? description[...]
        guard let bytes = Data(hexEncoded: description) else {
            throw HError(kind: .keyParse, description: "Invalid hex string")
        }
        return bytes
    }

    /// Creates a private key from raw bytes (defaults to Ed25519).
    private init(bytes: Data) throws {
        try self.init(ed25519Bytes: bytes)
    }

    /// Creates an Ed25519 private key from raw bytes (32 or 64 bytes).
    private init(ed25519Bytes bytes: Data) throws {
        guard bytes.count == 32 || bytes.count == 64 else {
            try self.init(derBytes: bytes)
            return
        }
        // swiftlint:disable:next force_try
        self.init(kind: .ed25519(try! .init(rawRepresentation: bytes.safeSubdata(in: 0..<32)!)))
    }

    /// Creates an ECDSA secp256k1 private key from raw bytes (32 bytes).
    private init(ecdsaBytes bytes: Data) throws {
        guard bytes.count == 32 else {
            try self.init(derBytes: bytes)
            return
        }
        do {
            self.init(kind: .ecdsa(try .init(dataRepresentation: bytes.safeSubdata(in: 0..<32)!)))
        } catch {
            throw HError.keyParse(String(describing: error))
        }
    }

    /// Creates a private key from DER-encoded PKCS#8 bytes.
    private init(derBytes bytes: Data) throws {
        let info: Pkcs8.PrivateKeyInfo
        let inner: ASN1OctetString
        do {
            info = try .init(derEncoded: Array(bytes))
            inner = try .init(derEncoded: info.privateKey.bytes)
        } catch {
            if let v = try? Self(sec1Bytes: bytes) {
                self = v
                return
            }
            throw HError.keyParse(String(describing: error))
        }

        switch info.algorithm.oid {
        case .AlgorithmIdentifier.ed25519: try self.init(ed25519Bytes: Data(inner.bytes))
        case .NamedCurves.secp256k1: try self.init(ecdsaBytes: Data(inner.bytes))
        case let oid:
            throw HError.keyParse("unsupported key algorithm: \(oid)")
        }
    }

    /// Creates an ECDSA private key from SEC1-encoded bytes.
    private init(sec1Bytes bytes: Data) throws {
        let info: Sec1.ECPrivateKey
        do {
            info = try .init(derEncoded: Array(bytes))
        } catch {
            throw HError.keyParse(String(describing: error))
        }

        switch info.parameters?.namedCurve {
        case .some(ASN1ObjectIdentifier.NamedCurves.secp256k1):
            try self.init(ecdsaBytes: Data(info.privateKey.bytes))
        case .some(let oid):
            throw HError.keyParse("unsupported key algorithm: \(oid)")
        case nil:
            throw HError.keyParse("missing curve parameters")
        }
    }

    /// Creates a private key by parsing a hex-encoded string.
    private init<S: StringProtocol>(parsing description: S) throws {
        try self.init(bytes: Self.decodeBytes(description))
    }

    /// Returns the algorithm identifier for PKCS#8 encoding.
    private var algorithm: Pkcs5.AlgorithmIdentifier {
        let oid: ASN1ObjectIdentifier
        switch self.guts {
        case .ed25519: oid = .AlgorithmIdentifier.ed25519
        case .ecdsa: oid = .NamedCurves.secp256k1
        }
        return .init(oid: oid)
    }

    // MARK: Generation

    /// Generates a new Ed25519 private key with a random chain code.
    ///
    /// - Returns: A new Ed25519 private key that supports key derivation.
    public static func generateEd25519() -> Self {
        Self(kind: .ed25519(.init()), chainCode: .randomData(withLength: 32))
    }

    /// Generates a new ECDSA secp256k1 private key.
    ///
    /// - Returns: A new ECDSA private key.
    public static func generateEcdsa() -> Self {
        // swiftlint:disable:next force_try
        .ecdsa(try! .init())
    }

    /// Creates an Ed25519 private key from the underlying crypto key.
    internal static func ed25519(_ key: Curve25519.Signing.PrivateKey) -> Self {
        Self(kind: .ed25519(key))
    }

    /// Creates an ECDSA private key from the underlying crypto key.
    internal static func ecdsa(_ key: secp256k1.Signing.PrivateKey) -> Self {
        Self(kind: .ecdsa(key))
    }

    // MARK: Public Properties

    /// The public key corresponding to this private key.
    public var publicKey: PublicKey {
        switch kind {
        case .ed25519(let key): return .ed25519(key.publicKey)
        case .ecdsa(let key): return .ecdsa(key.publicKey)
        }
    }

    /// A debug description of the private key (key material is redacted).
    public var debugDescription: String {
        "PrivateKey(kind: \(String(reflecting: guts)))"
    }

    // MARK: Parsing from Bytes

    /// Parses a private key from raw bytes.
    ///
    /// Attempts to parse as Ed25519 first, then falls back to DER format.
    ///
    /// - Parameter bytes: The key bytes.
    /// - Returns: The parsed private key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(bytes: bytes)
    }

    /// Parses an Ed25519 private key from raw bytes.
    ///
    /// - Parameter bytes: The 32-byte raw key or 64-byte expanded key.
    /// - Returns: The parsed Ed25519 private key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromBytesEd25519(_ bytes: Data) throws -> Self {
        try Self(ed25519Bytes: bytes)
    }

    /// Parses an ECDSA secp256k1 private key from raw bytes.
    ///
    /// - Parameter bytes: The 32-byte raw key or DER-encoded key.
    /// - Returns: The parsed ECDSA private key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromBytesEcdsa(_ bytes: Data) throws -> Self {
        try Self(ecdsaBytes: bytes)
    }

    /// Parses a private key from DER-encoded bytes.
    ///
    /// - Parameter bytes: The DER-encoded PKCS#8 private key.
    /// - Returns: The parsed private key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromBytesDer(_ bytes: Data) throws -> Self {
        try Self(derBytes: bytes)
    }

    // MARK: Parsing from Strings

    /// Parses a private key from a hex-encoded string.
    ///
    /// - Parameter description: The hex-encoded key (with optional "0x" prefix).
    /// - Returns: The parsed private key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromString<S: StringProtocol>(_ description: S) throws -> Self {
        try Self(parsing: description)
    }

    /// Creates a private key from a string, returning `nil` if parsing fails.
    public init?(_ description: String) {
        try? self.init(parsing: description)
    }

    /// Creates a private key from a string literal.
    ///
    /// - Warning: Crashes if the string is not a valid private key.
    public init(stringLiteral value: StringLiteralType) {
        // swiftlint:disable:next force_try
        try! self.init(parsing: value)
    }

    /// Parses a DER-encoded private key from a hex string.
    ///
    /// - Parameter description: The hex-encoded DER key.
    /// - Returns: The parsed private key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromStringDer<S: StringProtocol>(_ description: S) throws -> Self {
        try fromBytesDer(decodeBytes(description))
    }

    /// Parses an Ed25519 private key from a hex string.
    ///
    /// - Parameter description: The hex-encoded raw key.
    /// - Returns: The parsed Ed25519 private key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromStringEd25519(_ description: String) throws -> Self {
        try fromBytesEd25519(decodeBytes(description))
    }

    /// Parses an ECDSA secp256k1 private key from a hex string.
    ///
    /// - Parameter description: The hex-encoded raw key.
    /// - Returns: The parsed ECDSA private key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromStringEcdsa(_ description: String) throws -> Self {
        try fromBytesEcdsa(decodeBytes(description))
    }

    // MARK: Parsing from PEM

    /// Parses a private key from a PEM-encoded string.
    ///
    /// Supports both PKCS#8 (`PRIVATE KEY`) and SEC1 (`EC PRIVATE KEY`) formats.
    ///
    /// - Parameter pem: The PEM-encoded string.
    /// - Returns: The parsed private key.
    /// - Throws: `HError.keyParse` if parsing fails.
    /// - SeeAlso: [RFC 7468 Section 10](https://www.rfc-editor.org/rfc/rfc7468#section-10)
    public static func fromPem(_ pem: String) throws -> Self {
        let document = try Pem.decode(pem)

        switch document.typeLabel {
        case "PRIVATE KEY": return try fromBytesDer(document.der)
        case "EC PRIVATE KEY": return try Self(sec1Bytes: document.der)
        case let label:
            throw HError.keyParse("incorrect PEM type label: expected: `PRIVATE KEY`, got: `\(label)`")
        }
    }

    /// Parses a password-protected private key from a PEM-encoded string.
    ///
    /// Supports PKCS#8 encrypted keys and legacy OpenSSL-style encrypted EC keys.
    ///
    /// - Parameters:
    ///   - pem: The PEM-encoded string.
    ///   - password: The decryption password.
    /// - Returns: The decrypted private key.
    /// - Throws: `HError.keyParse` if parsing or decryption fails.
    /// - SeeAlso: [RFC 7468 Section 11](https://www.rfc-editor.org/rfc/rfc7468#section-11)
    public static func fromPem(_ pem: String, _ password: String) throws -> Self {
        let document = try Pem.decode(pem)

        switch document.typeLabel {
        case "ENCRYPTED PRIVATE KEY":
            guard document.headers.isEmpty else {
                throw HError.keyParse("expected pem document to have no headers")
            }

            let decrypted: Data
            do {
                let document = try Pkcs8.EncryptedPrivateKeyInfo(derEncoded: Array(document.der))
                decrypted = try document.decrypt(password: password.data(using: .utf8)!)
            } catch {
                throw HError.keyParse(String(describing: error))
            }

            return try fromBytesDer(decrypted)

        case "EC PRIVATE KEY":
            guard document.headers["Proc-Type"] == "4,ENCRYPTED" else {
                throw HError.keyParse("Encrypted EC Private Key missing or invalid `Proc-Type` header")
            }

            guard let dekInfo = document.headers["DEK-Info"] else {
                throw HError.keyParse("EC Private Key missing `DEK-Info` header")
            }

            guard let (alg, iv) = dekInfo.splitOnce(on: ",") else {
                throw HError.keyParse("Invalid `DEK-Info`")
            }

            guard let iv = Data(hexEncoded: iv) else {
                throw HError.keyParse("invalid IV: \(iv)")
            }

            let decrypted: Data

            switch alg {
            case "AES-128-CBC":
                guard iv.count == 16 else {
                    throw HError.keyParse("invalid IV")
                }

                var md5 = MD5Hasher()
                md5.update(data: password.data(using: .utf8)!)
                md5.update(data: iv[slicing: ..<8]!)
                let passphrase = Data(md5.finalize().bytes)

                do {
                    decrypted = try Aes.aes128CbcPadDecrypt(key: passphrase, iv: iv, message: document.der)
                } catch {
                    throw HError.keyParse("Failed to decrypt message: \(error)")
                }

            default:
                throw HError.keyParse("unexpected decryption alg: \(alg)")
            }

            return try Self(sec1Bytes: decrypted)

        case let label:
            throw HError.keyParse("incorrect PEM type label: expected: `PRIVATE KEY`, got: `\(label)`")
        }
    }

    // MARK: Serialization

    /// Serializes the private key to DER-encoded PKCS#8 format.
    ///
    /// - Returns: The DER-encoded bytes.
    public func toBytesDer() -> Data {
        let rawBytes = Array(toBytesRaw())
        let inner: [UInt8]
        do {
            var serializer = DER.Serializer()
            // swiftlint:disable:next force_try
            try! serializer.serialize(ASN1OctetString(contentBytes: rawBytes[...]))
            inner = serializer.serializedBytes
        }

        let info = Pkcs8.PrivateKeyInfo(algorithm: algorithm, privateKey: .init(contentBytes: inner[...]))
        var serializer = DER.Serializer()
        // swiftlint:disable:next force_try
        try! serializer.serialize(info)
        return Data(serializer.serializedBytes)
    }

    /// Serializes the private key to bytes.
    ///
    /// For Ed25519 keys, returns raw bytes. For ECDSA keys, returns DER-encoded bytes.
    ///
    /// - Returns: The serialized key bytes.
    public func toBytes() -> Data {
        switch kind {
        case .ed25519: return toBytesRaw()
        case .ecdsa: return toBytesDer()
        }
    }

    /// Serializes the private key to raw bytes (32 bytes).
    ///
    /// - Returns: The raw 32-byte private key.
    public func toBytesRaw() -> Data {
        switch kind {
        case .ecdsa(let ecdsa): return ecdsa.dataRepresentation
        case .ed25519(let ed25519): return ed25519.rawRepresentation
        }
    }

    /// The private key as a hex-encoded DER string.
    public var description: String {
        toStringDer()
    }

    /// Returns the private key as a hex string.
    ///
    /// - Returns: The hex-encoded DER representation.
    public func toString() -> String {
        String(describing: self)
    }

    /// Returns the private key as a hex-encoded DER string.
    ///
    /// - Returns: The hex-encoded DER representation.
    public func toStringDer() -> String {
        toBytesDer().hexStringEncoded()
    }

    /// Returns the private key as a hex-encoded raw string.
    ///
    /// - Returns: The hex-encoded raw 32-byte key.
    public func toStringRaw() -> String {
        toBytesRaw().hexStringEncoded()
    }

    /// Creates an account ID from this key's public key.
    ///
    /// - Parameters:
    ///   - shard: The shard number.
    ///   - realm: The realm number.
    /// - Returns: An account ID aliased to this key's public key.
    public func toAccountId(shard: UInt64, realm: UInt64) -> AccountId {
        publicKey.toAccountId(shard: shard, realm: realm)
    }

    // MARK: Type Checks

    /// Returns `true` if this is an Ed25519 key.
    public func isEd25519() -> Bool {
        if case .ed25519 = kind {
            return true
        }
        return false
    }

    /// Returns `true` if this is an ECDSA secp256k1 key.
    public func isEcdsa() -> Bool {
        if case .ecdsa = kind {
            return true
        }
        return false
    }

    // MARK: Signing

    /// Signs a message with this private key.
    ///
    /// For Ed25519 keys, signs the message directly.
    /// For ECDSA keys, signs the Keccak-256 hash of the message.
    ///
    /// - Parameter message: The message to sign.
    /// - Returns: The signature bytes.
    @Sendable
    public func sign(_ message: Data) -> Data {
        switch kind {
        case .ecdsa(let key):
            // swiftlint:disable:next force_try force_unwrapping
            return try! key.signature(for: Keccak256Digest(Keccak.keccak256(message))!).compactRepresentation
        case .ed25519(let key):
            // swiftlint:disable:next force_try
            return try! key.signature(for: message)
        }
    }

    // MARK: Key Derivation

    /// Returns `true` if this key supports BIP-32 derivation.
    ///
    /// A key is derivable if it's Ed25519 and has a chain code.
    public func isDerivable() -> Bool {
        isEd25519() && chainCode != nil
    }

    /// Derives a child key using BIP-32 derivation.
    ///
    /// - Parameter index: The derivation index (use `Bip32Utils.toHardenedIndex` for hardened derivation).
    /// - Returns: The derived child key with its own chain code.
    /// - Throws: `HError.keyDerive` if the key is not derivable.
    public func derive(_ index: Int32) throws -> Self {
        let index = UInt32(bitPattern: index)

        guard let chainCode = chainCode else {
            throw HError(kind: .keyDerive, description: "key is underivable")
        }

        switch kind {
        case .ecdsa(let key):
            let isHardened = Bip32Utils.isHardenedIndex(index)
            var data = Data()
            let priv = toBytesRaw()

            if isHardened {
                data.append(0x00)
                data.append(priv)
            } else {
                data.append(key.publicKey.dataRepresentation)
            }

            data.append(index.bigEndianBytes)

            var hmac = HMAC<SHA512Hash>(key: SymmetricKey(data: chainCode.data))
            hmac.update(data: data)
            let hmacResult = hmac.finalize()
            let il = Data(hmacResult.prefix(32))
            let newChainCode = Data(hmacResult.suffix(32))

            let parentPrivateKeyBigInt = BigInt(unsignedBEBytes: priv)
            let ilBigInt = BigInt(unsignedBEBytes: il)
            let childPrivateKeyBigInt = (parentPrivateKeyBigInt + ilBigInt) % secp256k1Order

            var childPrivateKeyData = childPrivateKeyBigInt.toBigEndianBytes()

            if childPrivateKeyData.count > 32 {
                childPrivateKeyData = childPrivateKeyData.suffix(32)
            } else if childPrivateKeyData.count < 32 {
                childPrivateKeyData = Data(repeating: 0, count: 32 - childPrivateKeyData.count) + childPrivateKeyData
            }

            guard let childPrivateKey = try? secp256k1.Signing.PrivateKey(dataRepresentation: childPrivateKeyData)
            else {
                throw NSError(
                    domain: "InvalidPrivateKey", code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to initialize secp256k1 private key. Key out of range."
                    ]
                )
            }

            // swiftlint:disable:next force_try
            return Self(
                kind: .ecdsa(try! .init(dataRepresentation: childPrivateKey.dataRepresentation)),
                chainCode: Data(newChainCode))

        case .ed25519(let key):
            let index = Bip32Utils.toHardenedIndex(index)

            var hmac = HMAC<SHA512Hash>(key: SymmetricKey(data: chainCode.data))
            hmac.update(data: [0])
            hmac.update(data: key.rawRepresentation)
            hmac.update(data: index.bigEndianBytes)
            let output = hmac.finalize().bytes

            let (data, chainCode) = (output[..<32], output[32...])

            // swiftlint:disable:next force_try
            return Self(kind: .ed25519(try! .init(rawRepresentation: Data(data))), chainCode: Data(chainCode))
        }
    }

    /// Derives a child key using the legacy derivation method.
    ///
    /// - Parameter index: The derivation index.
    /// - Returns: The derived child key.
    /// - Throws: `HError.keyDerive` if derivation fails.
    public func legacyDerive(_ index: Int64) throws -> Self {
        switch kind {
        case .ecdsa(let key):
            var seed = key.dataRepresentation
            seed.append(index.bigEndianBytes)

            let salt = Data([0xff])
            let derivedKey = Pkcs5.pbkdf2(sha: .sha512, password: seed, salt: salt, rounds: 2048, keySize: 32)

            guard let newKey = try? P256.Signing.PrivateKey(rawRepresentation: derivedKey) else {
                throw HError(kind: .keyDerive, description: "invalid derived key")
            }

            return try .fromBytesEcdsa(newKey.rawRepresentation)

        case .ed25519(let key):
            var seed = key.rawRepresentation

            let idx1: Int32
            switch index {
            case 0x00ff_ffff_ffff: idx1 = 0xff
            case 0...: idx1 = 0
            default: idx1 = -1
            }

            let idx2 = UInt8(truncatingIfNeeded: index)

            seed.append(idx1.bigEndianBytes)
            seed.append(Data([idx2, idx2, idx2, idx2]))

            let salt = Data([0xff])
            let key = Pkcs5.pbkdf2(sha: .sha512, password: seed, salt: salt, rounds: 2048, keySize: 32)

            return try .fromBytesEd25519(key)
        }
    }

    // MARK: From Seed / Mnemonic

    /// Creates an ECDSA secp256k1 private key from a BIP-39 seed.
    ///
    /// Uses the "Bitcoin seed" derivation path.
    ///
    /// - Parameter seed: The 64-byte BIP-39 seed.
    /// - Returns: The derived ECDSA private key with chain code.
    public static func fromSeedECDSAsecp256k1(_ seed: Data) -> Self {
        var hmac = HMAC<SHA512Hash>(key: SymmetricKey(data: "Bitcoin seed".data(using: .utf8)!))
        hmac.update(data: seed)

        let output = hmac.finalize().bytes
        let (data, chainCode) = (output[..<32], output[32...])

        // swiftlint:disable:next force_try
        return Self(kind: .ecdsa(try! .init(dataRepresentation: data)), chainCode: Data(chainCode))
    }

    /// Creates an Ed25519 private key from a BIP-39 seed.
    ///
    /// Uses the Hedera derivation path: `m/44'/3030'/0'/0'`.
    ///
    /// - Parameter seed: The 64-byte BIP-39 seed.
    /// - Returns: The derived Ed25519 private key with chain code.
    public static func fromSeedED25519(_ seed: Data) -> Self {
        var hmac = HMAC<SHA512Hash>(key: SymmetricKey(data: "ed25519 seed".data(using: .utf8)!))
        hmac.update(data: seed)

        let output = hmac.finalize().bytes
        let (data, chainCode) = (output[..<32], output[32...])

        // swiftlint:disable:next force_try
        var key = Self(kind: .ed25519(try! .init(rawRepresentation: Data(data))), chainCode: Data(chainCode))

        // Hedera derivation path: m/44'/3030'/0'/0'
        for index: Int32 in [44, 3030, 0, 0] {
            // swiftlint:disable:next force_try
            key = try! key.derive(index)
        }

        return key
    }

    /// Creates an Ed25519 private key from a mnemonic phrase.
    ///
    /// - Parameters:
    ///   - mnemonic: The BIP-39 mnemonic.
    ///   - passphrase: Optional passphrase for seed derivation.
    /// - Returns: The derived Ed25519 private key.
    public static func fromMnemonic(_ mnemonic: Mnemonic, _ passphrase: String) -> Self {
        fromSeedED25519(mnemonic.toSeed(passphrase: passphrase))
    }

    /// Creates an Ed25519 private key from a mnemonic phrase (no passphrase).
    ///
    /// - Parameter mnemonic: The BIP-39 mnemonic.
    /// - Returns: The derived Ed25519 private key.
    public static func fromMnemonic(_ mnemonic: Mnemonic) -> Self {
        Self.fromMnemonic(mnemonic, "")
    }

    // MARK: Transaction Signing

    /// Signs a transaction with this private key.
    ///
    /// - Parameter transaction: The transaction to sign.
    /// - Returns: The signature bytes.
    /// - Throws: If the transaction cannot be frozen.
    public func signTransaction(_ transaction: Transaction) throws -> Data {
        try transaction.freeze()
        return transaction.addSignatureSigner(.privateKey(self))
    }
}

// MARK: - Testing Helpers

extension PrivateKey {
    /// Creates a copy of this key with a different chain code (for testing).
    internal func withChainCode(chainCode: Data) -> Self {
        precondition(chainCode.count == 32)
        return Self(kind: kind, chainCode: chainCode)
    }

    /// Returns a pretty-printed representation of the key (for testing).
    internal func prettyPrint() -> String {
        let data = toStringRaw()
        let chainCode = String(describing: chainCode?.data.hexStringEncoded())

        let start: String
        switch guts {
        case .ecdsa: start = "PrivateKey.ecdsa"
        case .ed25519: start = "PrivateKey.ed25519"
        }

        return """
            \(start)(
                key: \(data),
                chainCode: \(chainCode)
            )
            """
    }
}

// MARK: - Supporting Types

// MARK: ChainCode

/// HD wallet chain code used for hierarchical key derivation (BIP-32).
///
/// The chain code is 32 bytes of additional entropy used alongside the private key
/// to derive child keys in a deterministic manner.
public struct ChainCode {
    /// The 32-byte chain code data.
    internal let data: Data
}

// MARK: MD5Hasher (Legacy)

/// Incremental MD5 hasher for computing MD5 digests.
///
/// - Warning: MD5 is cryptographically broken. Use only for non-security purposes
///   such as checksums in legacy protocols. For security, use SHA-256 or higher.
internal struct MD5Hasher {
    /// The underlying MD5 hash state.
    private var md5: Insecure.MD5

    /// Creates a new MD5 hasher.
    internal init() {
        self.md5 = Insecure.MD5()
    }

    /// Updates the hash with additional data.
    ///
    /// - Parameter data: The data to add to the hash.
    internal mutating func update(data: Data) {
        md5.update(data: data)
    }

    /// Finalizes the hash and returns the digest.
    ///
    /// - Returns: The 16-byte MD5 digest.
    internal func finalize() -> Data {
        Data(md5.finalize())
    }
}

// MARK: - Sendable Conformances

#if compiler(>=5.7)
    extension ChainCode: Sendable {}
    extension PrivateKey.Repr: Sendable {}
#else
    extension ChainCode: @unchecked Sendable {}
    extension PrivateKey.Repr: @unchecked Sendable {}
#endif

extension PrivateKey: Sendable {}
