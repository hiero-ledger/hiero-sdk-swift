// SPDX-License-Identifier: Apache-2.0

/// Public key implementation for the Hiero SDK.
///
/// This file provides:
/// - `PublicKey` - Ed25519 or ECDSA secp256k1 public key
///
/// Supported key types:
/// - **Ed25519**: Used for EdDSA signature verification
/// - **ECDSA secp256k1**: Used for Ethereum-compatible signature verification

import Crypto
import Foundation
import HieroProtobufs
import SwiftASN1
import secp256k1
import secp256k1_bindings

// MARK: - PublicKey

/// A public key for a Hiero network.
///
/// Supports two key types:
/// - **Ed25519**: The default key type, used for EdDSA signature verification
/// - **ECDSA secp256k1**: Used for Ethereum-compatible signature verification
///
/// ## Parsing Keys
/// ```swift
/// let key = try PublicKey.fromString("302a300506...")
/// let ed25519Key = try PublicKey.fromBytesEd25519(bytes)
/// ```
///
/// ## Verifying Signatures
/// ```swift
/// try publicKey.verify(message, signature)
/// ```
public struct PublicKey: LosslessStringConvertible, ExpressibleByStringLiteral, Equatable, Hashable {
    // MARK: Private Properties

    /// Internal representation for `Sendable` conformance.
    private let guts: Repr

    /// Reconstructed key (computed on access).
    private var kind: Kind {
        guts.kind
    }

    // MARK: Private Types

    /// Sendable-compatible representation of the key.
    fileprivate enum Repr {
        /// Ed25519 key stored as raw bytes.
        case ed25519(Data)
        /// ECDSA secp256k1 key stored as raw bytes with compression flag.
        case ecdsa(Data, compressed: Bool)

        /// Creates a representation from the actual key type.
        fileprivate init(kind: PublicKey.Kind) {
            switch kind {
            case .ecdsa(let key): self = .ecdsa(key.dataRepresentation, compressed: key.format == .compressed)
            case .ed25519(let key): self = .ed25519(key.rawRepresentation)
            }
        }

        /// Reconstructs the actual key type from the stored bytes.
        fileprivate var kind: PublicKey.Kind {
            switch self {
            case .ecdsa(let key, let compressed):
                // swiftlint:disable:next force_try
                return .ecdsa(try! .init(dataRepresentation: key, format: compressed ? .compressed : .uncompressed))
            case .ed25519(let key):
                // swiftlint:disable:next force_try
                return .ed25519(try! .init(rawRepresentation: key))
            }
        }
    }

    /// The actual key type.
    fileprivate enum Kind {
        /// Ed25519 key for EdDSA signature verification.
        case ed25519(Curve25519.Signing.PublicKey)
        /// ECDSA secp256k1 key for Ethereum-compatible signature verification.
        case ecdsa(secp256k1.Signing.PublicKey)
    }

    // MARK: Initializers (Private)

    /// Creates a public key with the specified kind.
    private init(_ kind: Kind) {
        self.guts = .init(kind: kind)
    }

    /// Decodes hex-encoded bytes, stripping optional "0x" prefix.
    private static func decodeBytes<S: StringProtocol>(_ description: S) throws -> Data {
        let description = description.stripPrefix("0x") ?? description[...]
        guard let bytes = Data(hexEncoded: description) else {
            throw HError(kind: .keyParse, description: "Invalid hex string")
        }
        return bytes
    }

    /// Creates a public key from raw bytes, auto-detecting the key type.
    private init(bytes: Data) throws {
        switch bytes.count {
        case 32: try self.init(ed25519Bytes: bytes)
        case 33: try self.init(ecdsaBytes: bytes)
        default: try self.init(derBytes: bytes)
        }
    }

    /// Creates an Ed25519 public key from raw bytes (32 bytes).
    fileprivate init(ed25519Bytes bytes: Data) throws {
        guard bytes.count == 32 else {
            try self.init(derBytes: bytes)
            return
        }
        do {
            self.init(.ed25519(try .init(rawRepresentation: bytes)))
        } catch {
            throw HError.keyParse(String(describing: error))
        }
    }

    /// Creates an ECDSA secp256k1 public key from raw bytes (33 or 65 bytes).
    fileprivate init(ecdsaBytes bytes: Data) throws {
        switch bytes.count {
        case secp256k1.Format.compressed.length:
            do {
                self.init(.ecdsa(try .init(dataRepresentation: bytes, format: .compressed)))
            } catch {
                throw HError.keyParse(String(describing: error))
            }
        case secp256k1.Format.uncompressed.length:
            do {
                self.init(.ecdsa(try .init(dataRepresentation: bytes, format: .uncompressed)))
            } catch {
                throw HError.keyParse(String(describing: error))
            }
        default:
            try self.init(derBytes: bytes)
        }
    }

    /// Creates a public key from DER-encoded SubjectPublicKeyInfo bytes.
    private init(derBytes bytes: Data) throws {
        let info: Pkcs8.SubjectPublicKeyInfo

        do {
            info = try .init(derEncoded: Array(bytes))
        } catch {
            throw HError.keyParse(String(describing: error))
        }

        switch info.algorithm.oid {
        case .NamedCurves.secp256k1,
            .AlgorithmIdentifier.idEcPublicKey
        where info.algorithm.parametersOID == ASN1ObjectIdentifier.NamedCurves.secp256k1:
            guard info.subjectPublicKey.paddingBits == 0 else {
                throw HError.keyParse("Invalid padding for secp256k1 spki")
            }
            try self.init(ecdsaBytes: Data(info.subjectPublicKey.bytes))

        case .AlgorithmIdentifier.ed25519:
            guard info.subjectPublicKey.paddingBits == 0 else {
                throw HError.keyParse("Invalid padding for ed25519 spki")
            }
            try self.init(ed25519Bytes: Data(info.subjectPublicKey.bytes))

        default:
            throw HError.keyParse("Unknown public key OID \(info.algorithm.oid)")
        }
    }

    /// Creates a public key by parsing a hex-encoded string.
    private init(parsing description: String) throws {
        try self.init(bytes: Self.decodeBytes(description))
    }

    /// Returns the algorithm identifier for PKCS#8 encoding.
    private var algorithm: Pkcs5.AlgorithmIdentifier {
        let oid: ASN1ObjectIdentifier
        switch guts {
        case .ed25519: oid = .AlgorithmIdentifier.ed25519
        case .ecdsa: oid = .NamedCurves.secp256k1
        }
        return .init(oid: oid)
    }

    // MARK: Internal Factory Methods

    /// Creates an Ed25519 public key from the underlying crypto key.
    internal static func ed25519(_ key: Curve25519.Signing.PublicKey) -> Self {
        Self(.ed25519(key))
    }

    /// Creates an ECDSA public key from the underlying crypto key.
    internal static func ecdsa(_ key: secp256k1.Signing.PublicKey) -> Self {
        Self(.ecdsa(key))
    }

    /// Parses a public key from an account alias (protobuf bytes).
    ///
    /// - Parameter bytes: The protobuf-encoded key bytes.
    /// - Returns: The parsed public key, or `nil` if bytes are empty.
    /// - Throws: `HError.fromProtobuf` if parsing fails.
    internal static func fromAliasBytes(_ bytes: Data) throws -> PublicKey? {
        if bytes.isEmpty {
            return nil
        }

        switch try Key(protobufBytes: bytes) {
        case .single(let key):
            return key
        default:
            throw HError.fromProtobuf("Unexpected key kind in Account alias")
        }
    }

    // MARK: Parsing from Bytes

    /// Parses a public key from raw bytes.
    ///
    /// Automatically detects the key type based on byte length:
    /// - 32 bytes: Ed25519
    /// - 33 bytes: ECDSA compressed
    /// - Other: Attempts DER decoding
    ///
    /// - Parameter bytes: The key bytes.
    /// - Returns: The parsed public key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(bytes: bytes)
    }

    /// Parses an Ed25519 public key from raw bytes.
    ///
    /// - Parameter bytes: The 32-byte raw key.
    /// - Returns: The parsed Ed25519 public key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromBytesEd25519(_ bytes: Data) throws -> Self {
        try Self(ed25519Bytes: bytes)
    }

    /// Parses an ECDSA secp256k1 public key from raw bytes.
    ///
    /// - Parameter bytes: The compressed (33 bytes) or uncompressed (65 bytes) key.
    /// - Returns: The parsed ECDSA public key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromBytesEcdsa(_ bytes: Data) throws -> Self {
        try Self(ecdsaBytes: bytes)
    }

    /// Parses a public key from DER-encoded bytes.
    ///
    /// - Parameter bytes: The DER-encoded SubjectPublicKeyInfo.
    /// - Returns: The parsed public key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromBytesDer(_ bytes: Data) throws -> Self {
        try Self(derBytes: bytes)
    }

    // MARK: Parsing from Strings

    /// Parses a public key from a hex-encoded string.
    ///
    /// - Parameter description: The hex-encoded key (with optional "0x" prefix).
    /// - Returns: The parsed public key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromString(_ description: String) throws -> Self {
        try Self(parsing: description)
    }

    /// Creates a public key from a string, returning `nil` if parsing fails.
    public init?(_ description: String) {
        try? self.init(parsing: description)
    }

    /// Creates a public key from a string literal.
    ///
    /// - Warning: Crashes if the string is not a valid public key.
    public init(stringLiteral value: StringLiteralType) {
        // swiftlint:disable:next force_try
        try! self.init(parsing: value)
    }

    /// Parses a DER-encoded public key from a hex string.
    ///
    /// - Parameter description: The hex-encoded DER key.
    /// - Returns: The parsed public key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromStringDer(_ description: String) throws -> Self {
        try fromBytesDer(decodeBytes(description))
    }

    /// Parses an Ed25519 public key from a hex string.
    ///
    /// - Parameter description: The hex-encoded raw key.
    /// - Returns: The parsed Ed25519 public key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromStringEd25519(_ description: String) throws -> Self {
        try fromBytesEd25519(decodeBytes(description))
    }

    /// Parses an ECDSA secp256k1 public key from a hex string.
    ///
    /// - Parameter description: The hex-encoded raw key.
    /// - Returns: The parsed ECDSA public key.
    /// - Throws: `HError.keyParse` if parsing fails.
    public static func fromStringEcdsa(_ description: String) throws -> Self {
        try fromBytesEcdsa(decodeBytes(description))
    }

    // MARK: Serialization

    /// Serializes the public key to DER-encoded SubjectPublicKeyInfo format.
    ///
    /// - Returns: The DER-encoded bytes.
    public func toBytesDer() -> Data {
        let spki = Pkcs8.SubjectPublicKeyInfo(
            algorithm: algorithm,
            subjectPublicKey: ASN1BitString(bytes: Array(toBytesRaw())[...])
        )

        var serializer = DER.Serializer()
        // swiftlint:disable:next force_try
        try! serializer.serialize(spki)
        return Data(serializer.serializedBytes)
    }

    /// Serializes the public key to bytes.
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

    /// Serializes the public key to raw bytes.
    ///
    /// For Ed25519, returns 32 bytes. For ECDSA, returns 33 bytes (compressed).
    ///
    /// - Returns: The raw public key bytes.
    public func toBytesRaw() -> Data {
        switch kind {
        case .ecdsa(let key): return key.toBytes(format: .compressed)
        case .ed25519(let key): return key.rawRepresentation
        }
    }

    /// The public key as a hex-encoded DER string.
    public var description: String {
        toBytesDer().hexStringEncoded()
    }

    /// Returns the public key as a hex string.
    ///
    /// - Returns: The hex-encoded DER representation.
    public func toString() -> String {
        String(describing: self)
    }

    /// Returns the public key as a hex-encoded DER string.
    ///
    /// - Returns: The hex-encoded DER representation.
    public func toStringDer() -> String {
        toBytesDer().hexStringEncoded()
    }

    /// Returns the public key as a hex-encoded raw string.
    ///
    /// - Returns: The hex-encoded raw bytes.
    public func toStringRaw() -> String {
        toBytesRaw().hexStringEncoded()
    }

    /// Creates an account ID aliased to this public key.
    ///
    /// - Parameters:
    ///   - shard: The shard number.
    ///   - realm: The realm number.
    /// - Returns: An account ID aliased to this public key.
    public func toAccountId(shard: UInt64, realm: UInt64) -> AccountId {
        AccountId(shard: shard, realm: realm, alias: self)
    }

    // MARK: Verification

    /// Verifies a signature against this public key.
    ///
    /// For Ed25519 keys, verifies the signature directly.
    /// For ECDSA keys, verifies against the Keccak-256 hash of the message.
    ///
    /// - Parameters:
    ///   - message: The original message that was signed.
    ///   - signature: The signature to verify.
    /// - Throws: `HError.signatureVerify` if the signature is invalid.
    public func verify(_ message: Data, _ signature: Data) throws {
        switch self.kind {
        case .ed25519(let key):
            guard key.isValidSignature(signature, for: message) else {
                throw HError(kind: .signatureVerify, description: "invalid signature")
            }

        case .ecdsa(let key):
            let isValid: Bool
            do {
                isValid = try key.isValidSignature(
                    .init(compactRepresentation: signature),
                    // swiftlint:disable:next force_unwrapping
                    for: Keccak256Digest(Keccak.keccak256(message))!)
            } catch {
                throw HError(kind: .signatureVerify, description: "invalid signature")
            }

            guard isValid else {
                throw HError(kind: .signatureVerify, description: "invalid signature")
            }
        }
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

    // MARK: Equatable & Hashable

    /// Compares two public keys for equality using their DER representation.
    public static func == (lhs: PublicKey, rhs: PublicKey) -> Bool {
        lhs.toBytesDer() == rhs.toBytesDer()
    }

    /// Hashes the public key using its DER representation.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(toBytesDer())
    }

    // MARK: EVM Address

    /// Converts this public key to an EVM address (ECDSA only).
    ///
    /// The EVM address is the rightmost 20 bytes of the Keccak-256 hash
    /// of the uncompressed public key (without the 0x04 prefix byte).
    ///
    /// - Returns: The EVM address, or `nil` if this is not an ECDSA key.
    public func toEvmAddress() -> EvmAddress? {
        guard case .ecdsa(let key) = self.kind else {
            return nil
        }

        let output = key.toBytes(format: .uncompressed)
        let hash = Keccak.keccak256(output[1...])

        // swiftlint:disable:next force_try
        return try! EvmAddress(Data(hash.dropFirst(12)))
    }

    // MARK: Transaction Verification

    /// Verifies that this public key signed all transactions in the sources.
    ///
    /// - Parameter sources: The transaction sources to verify.
    /// - Throws: `HError.signatureVerify` if verification fails.
    internal func verifyTransactionSources(_ sources: TransactionSources) throws {
        let pkBytes = self.toBytesRaw()

        for signedTransaction in sources.signedTransactions {
            var found = false

            for sigPair in signedTransaction.sigMap.sigPair
            where pkBytes.starts(with: sigPair.pubKeyPrefix) {
                found = true

                let signature: Data
                switch sigPair.signature {
                case .ecdsaSecp256K1(let data), .ed25519(let data): signature = data
                default: throw HError(kind: .signatureVerify, description: "Unsupported transaction signature type")
                }

                try verify(signedTransaction.bodyBytes, signature)
            }

            if !found {
                throw HError(kind: .signatureVerify, description: "signer not in transaction")
            }
        }
    }

    /// Verifies that this public key signed the transaction.
    ///
    /// - Parameter transaction: The transaction to verify.
    /// - Throws: `HError.signatureVerify` if verification fails.
    public func verifyTransaction(_ transaction: Transaction) throws {
        if transaction.signers.contains(where: { self == $0.publicKey }) {
            return
        }

        guard let sources = transaction.sources else {
            throw HError(kind: .signatureVerify, description: "signer not in transaction")
        }

        try verifyTransactionSources(sources)
    }
}

// MARK: - Protobuf Conformance

extension PublicKey: TryProtobufCodable {
    /// The protobuf type used for serialization.
    internal typealias Protobuf = Proto_Key

    /// Creates a public key from a protobuf representation.
    ///
    /// - Parameter proto: The protobuf key.
    /// - Throws: `HError.fromProtobuf` if the key type is unsupported.
    internal init(protobuf proto: Proto_Key) throws {
        guard let key = proto.key else {
            throw HError.fromProtobuf("Key protobuf kind was unexpectedly `nil`")
        }

        switch key {
        case .ed25519(let bytes):
            try self.init(ed25519Bytes: bytes)

        case .ecdsaSecp256K1(let bytes):
            try self.init(ecdsaBytes: bytes)

        case .contractID:
            throw HError.fromProtobuf("unsupported Contract ID key in single key")

        case .delegatableContractID:
            throw HError.fromProtobuf("unsupported Delegatable Contract ID key in single key")

        case .rsa3072:
            throw HError.fromProtobuf("unsupported RSA-3072 key in single key")

        case .ecdsa384:
            throw HError.fromProtobuf("unsupported ECDSA-384 key in single key")

        case .thresholdKey:
            throw HError.fromProtobuf("unsupported threshold key in single key")

        case .keyList:
            throw HError.fromProtobuf("unsupported keylist in single key")
        }
    }

    /// Converts this public key to a protobuf representation.
    ///
    /// - Returns: The protobuf key.
    internal func toProtobuf() -> Protobuf {
        .with { proto in
            switch self.guts {
            case .ed25519: proto.ed25519 = toBytesRaw()
            case .ecdsa: proto.ecdsaSecp256K1 = toBytesRaw()
            }
        }
    }
}

// MARK: - secp256k1 Extensions

extension secp256k1.Signing.PublicKey {
    /// Serializes the public key to bytes in the specified format.
    ///
    /// - Parameter format: The serialization format (compressed or uncompressed).
    /// - Returns: The serialized public key bytes.
    internal func toBytes(format: secp256k1.Format) -> Data {
        let context = secp256k1.Context.rawRepresentation

        var pubkey = secp256k1_pubkey()

        self.dataRepresentation.withUnsafeTypedBytes { bytes in
            let result = secp256k1_bindings.secp256k1_ec_pubkey_parse(
                context,
                &pubkey,
                bytes.baseAddress!,
                bytes.count
            )
            precondition(result == 1)
        }

        var output = Data(repeating: 0, count: format.length)

        output.withUnsafeMutableTypedBytes { output in
            var outputLen = output.count
            let result = secp256k1_ec_pubkey_serialize(
                context,
                output.baseAddress!,
                &outputLen,
                &pubkey,
                format.rawValue
            )
            precondition(result == 1)
            precondition(outputLen == output.count)
        }

        return output
    }
}

// MARK: - Sendable Conformances

#if compiler(>=5.7)
    extension PublicKey.Repr: Sendable {}
#else
    extension PublicKey.Repr: @unchecked Sendable {}
#endif

extension PublicKey: Sendable {}
