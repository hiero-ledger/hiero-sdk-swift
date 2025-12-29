// SPDX-License-Identifier: Apache-2.0

// MARK: - PKCS#8 Private Key Format

/// PKCS#8 (Public-Key Cryptography Standards #8) defines a standard syntax
/// for storing private key information. This is the most common format for
/// private keys in PEM files.
///
/// PEM Type Labels:
/// - "PRIVATE KEY" → PrivateKeyInfo (unencrypted)
/// - "ENCRYPTED PRIVATE KEY" → EncryptedPrivateKeyInfo (encrypted with password)
///
/// Key formats wrapped by PKCS#8:
/// - Ed25519 keys (32-byte raw key)
/// - ECDSA keys (SEC1 format)
///
/// Reference: RFC 5958 (https://tools.ietf.org/html/rfc5958)

import Foundation
import SwiftASN1

/// PKCS#8 private key structures.
///
/// PKCS#8 provides a standard way to encode private keys along with
/// their algorithm identifier. This allows keys of different types
/// to be stored in a consistent format.
///
/// ## Example
/// ```swift
/// // Parse unencrypted private key
/// let keyInfo = try Pkcs8.PrivateKeyInfo(derEncoded: derData)
///
/// // Parse and decrypt encrypted private key
/// let encryptedInfo = try Pkcs8.EncryptedPrivateKeyInfo(derEncoded: derData)
/// let decryptedDER = try encryptedInfo.decrypt(password: passwordData)
/// ```
internal enum Pkcs8 {

    // MARK: - Type Aliases

    /// Algorithm identifier for the private key type.
    internal typealias PrivateKeyAlgorithmIdentifier = Pkcs5.AlgorithmIdentifier

    /// The raw private key bytes.
    ///
    /// The format of these bytes depends on the algorithm:
    /// - Ed25519: 32-byte raw key
    /// - ECDSA: SEC1-encoded key
    ///
    /// ```text
    /// PrivateKey ::= OCTET STRING
    /// ```
    internal typealias PrivateKey = ASN1OctetString

    /// Optional public key associated with the private key.
    ///
    /// ```text
    /// PublicKey ::= BIT STRING
    /// ```
    internal typealias PublicKey = ASN1BitString

    /// Encrypted private key data.
    ///
    /// ```text
    /// EncryptedData ::= OCTET STRING
    /// ```
    internal typealias EncryptedData = ASN1OctetString

    // MARK: - PrivateKeyInfo (Unencrypted)

    /// PKCS#8 private key info (unencrypted).
    ///
    /// This is the structure encoded in PEM files with "PRIVATE KEY" type label.
    ///
    /// Version 1 (v1):
    /// ```text
    /// PrivateKeyInfo ::= SEQUENCE {
    ///   version                   Version,
    ///   privateKeyAlgorithm       PrivateKeyAlgorithmIdentifier,
    ///   privateKey                PrivateKey,
    ///   attributes           [0]  IMPLICIT Attributes OPTIONAL }
    /// ```
    ///
    /// Version 2 (v2) adds optional public key:
    /// ```text
    /// OneAsymmetricKey ::= SEQUENCE {
    ///   version                   Version,
    ///   privateKeyAlgorithm       PrivateKeyAlgorithmIdentifier,
    ///   privateKey                PrivateKey,
    ///   attributes            [0] Attributes OPTIONAL,
    ///   ...,
    ///   [[2: publicKey        [1] PublicKey OPTIONAL ]],
    ///   ...
    /// }
    /// ```
    internal struct PrivateKeyInfo {
        /// The algorithm identifier (e.g., Ed25519, ECDSA with secp256k1).
        internal let algorithm: PrivateKeyAlgorithmIdentifier

        /// The encoded private key bytes.
        internal let privateKey: ASN1OctetString

        /// Optional public key (present in v2 format).
        internal let publicKey: ASN1BitString?

        /// Create a private key info structure.
        ///
        /// - Parameters:
        ///   - algorithm: The algorithm identifier.
        ///   - privateKey: The encoded private key.
        ///   - publicKey: Optional public key (if present, uses v2 format).
        internal init(
            algorithm: Pkcs8.PrivateKeyAlgorithmIdentifier,
            privateKey: ASN1OctetString,
            publicKey: ASN1BitString? = nil
        ) {
            self.algorithm = algorithm
            self.privateKey = privateKey
            self.publicKey = publicKey
        }

        /// The PKCS#8 version based on whether public key is present.
        fileprivate var version: Version {
            publicKey != nil ? .v2 : .v1
        }
    }

    // MARK: - EncryptedPrivateKeyInfo

    /// PKCS#8 encrypted private key info.
    ///
    /// This is the structure encoded in PEM files with "ENCRYPTED PRIVATE KEY" type label.
    /// The private key is encrypted using password-based encryption (PBES2).
    ///
    /// ```text
    /// EncryptedPrivateKeyInfo ::= SEQUENCE {
    ///   encryptionAlgorithm  EncryptionAlgorithmIdentifier,
    ///   encryptedData        EncryptedData }
    ///
    /// EncryptionAlgorithmIdentifier ::= AlgorithmIdentifier
    /// ```
    internal struct EncryptedPrivateKeyInfo {
        /// The encryption algorithm with parameters (typically PBES2).
        internal let encryptionAlgorithm: Pkcs5.EncryptionScheme

        /// The encrypted PrivateKeyInfo bytes.
        internal let encryptedData: ASN1OctetString

        /// Decrypt the encrypted private key using a password.
        ///
        /// - Parameter password: The password used to encrypt the key.
        /// - Returns: The decrypted private key data (DER-encoded PrivateKeyInfo).
        /// - Throws: An error if the password is incorrect or decryption fails.
        internal func decrypt(password: Data) throws -> Data {
            try encryptionAlgorithm.decrypt(password: password, document: Data(encryptedData.bytes))
        }
    }

    // MARK: - SubjectPublicKeyInfo

    /// X.509 subject public key info structure.
    ///
    /// Used for encoding public keys in a format that includes the algorithm identifier.
    ///
    /// ```text
    /// SubjectPublicKeyInfo  ::=  SEQUENCE  {
    ///   algorithm            AlgorithmIdentifier,
    ///   subjectPublicKey     BIT STRING  }
    /// ```
    internal struct SubjectPublicKeyInfo {
        /// The algorithm identifier (e.g., Ed25519, ECDSA).
        internal let algorithm: Pkcs5.AlgorithmIdentifier

        /// The encoded public key bits.
        internal let subjectPublicKey: ASN1BitString
    }

    // MARK: - Version (Internal)

    /// PKCS#8 version number.
    ///
    /// ```text
    /// Version ::= Integer { { v1(0), v2(1) } (v1, ..., v2) }
    /// ```
    fileprivate enum Version: Int, Equatable {
        /// Version 1: Basic format without public key.
        case v1 = 0
        /// Version 2: Extended format with optional public key.
        case v2 = 1
    }
}

// MARK: - PrivateKeyInfo DER Conformance

extension Pkcs8.PrivateKeyInfo: DERImplicitlyTaggable {
    /// Tag number for the optional public key field.
    private static let publicKeyTagNumber: UInt = 1

    /// The default ASN.1 identifier (SEQUENCE).
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// Parses the PrivateKeyInfo structure including version validation.
    ///
    /// - Parameters:
    ///   - rootNode: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: `ASN1Error.invalidASN1Object` if parsing fails or version is inconsistent.
    internal init(derEncoded rootNode: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(rootNode, identifier: identifier) { nodes in
            let version = try Pkcs8.Version(derEncoded: &nodes)
            let algorithmIdentifier = try Pkcs8.PrivateKeyAlgorithmIdentifier(derEncoded: &nodes)
            let privateKey = try Pkcs8.PrivateKey(derEncoded: &nodes)
            let publicKey = try DER.optionalExplicitlyTagged(
                &nodes,
                tagNumber: Self.publicKeyTagNumber,
                tagClass: .contextSpecific,
                Pkcs8.PublicKey.init(derEncoded:)
            )

            // Validate version matches public key presence
            switch (version, publicKey != nil) {
            case (.v1, false), (.v2, true): break
            case (.v1, true), (.v2, false):
                throw ASN1Error.invalidASN1Object
            }

            return Self(algorithm: algorithmIdentifier, privateKey: privateKey, publicKey: publicKey)
        }
    }

    /// Serialize to DER-encoded ASN.1 format.
    ///
    /// - Parameters:
    ///   - coder: The serializer to write to.
    ///   - identifier: The ASN.1 identifier to use.
    /// - Throws: An error if serialization fails.
    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(version)
            try coder.serialize(algorithm)
            try coder.serialize(privateKey)

            if let publicKey = publicKey {
                try coder.serialize(
                    publicKey,
                    explicitlyTaggedWithTagNumber: Self.publicKeyTagNumber,
                    tagClass: .contextSpecific
                )
            }
        }
    }
}

// MARK: - EncryptedPrivateKeyInfo DER Conformance

extension Pkcs8.EncryptedPrivateKeyInfo: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (SEQUENCE).
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: An error if parsing fails.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(derEncoded, identifier: identifier) { nodes in
            let encryptionAlgorithm = try Pkcs5.EncryptionScheme(derEncoded: &nodes)
            let encryptedData = try ASN1OctetString(derEncoded: &nodes)

            return Self(encryptionAlgorithm: encryptionAlgorithm, encryptedData: encryptedData)
        }
    }

    /// Serialize to DER-encoded ASN.1 format.
    ///
    /// - Parameters:
    ///   - coder: The serializer to write to.
    ///   - identifier: The ASN.1 identifier to use.
    /// - Throws: An error if serialization fails.
    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(encryptionAlgorithm)
            try coder.serialize(encryptedData)
        }
    }
}

// MARK: - SubjectPublicKeyInfo DER Conformance

extension Pkcs8.SubjectPublicKeyInfo: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (SEQUENCE).
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: An error if parsing fails.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(derEncoded, identifier: identifier) { nodes in
            let algId = try Pkcs5.AlgorithmIdentifier(derEncoded: &nodes)
            let subjectPublicKey = try ASN1BitString(derEncoded: &nodes)

            return Self(algorithm: algId, subjectPublicKey: subjectPublicKey)
        }
    }

    /// Serialize to DER-encoded ASN.1 format.
    ///
    /// - Parameters:
    ///   - coder: The serializer to write to.
    ///   - identifier: The ASN.1 identifier to use.
    /// - Throws: An error if serialization fails.
    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(algorithm)
            try coder.serialize(subjectPublicKey)
        }
    }
}

// MARK: - Version DER Conformance

extension Pkcs8.Version: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (INTEGER).
    fileprivate static var defaultIdentifier: ASN1Identifier { .integer }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: `ASN1Error.invalidASN1Object` if the version is unrecognized.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        let raw = try Int(derEncoded: derEncoded, withIdentifier: identifier)

        guard let value = Self(rawValue: raw) else {
            throw ASN1Error.invalidASN1Object
        }

        self = value
    }

    /// Serialize to DER-encoded ASN.1 format.
    ///
    /// - Parameters:
    ///   - coder: The serializer to write to.
    ///   - identifier: The ASN.1 identifier to use (ignored, uses INTEGER).
    /// - Throws: An error if serialization fails.
    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.serialize(self.rawValue)
    }
}
