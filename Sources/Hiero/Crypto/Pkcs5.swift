// SPDX-License-Identifier: Apache-2.0

// MARK: - PKCS#5 Password-Based Cryptography

/// PKCS#5 (Public-Key Cryptography Standards #5) defines methods for
/// encrypting data using a password-derived key. This implementation
/// supports PBES2 (Password-Based Encryption Scheme 2).
///
/// Used for decrypting PKCS#8 encrypted private keys.
///
/// Reference: RFC 8018 (https://tools.ietf.org/html/rfc8018)
///
/// File organization:
/// - Pkcs5.swift (this file): Entry point + AlgorithmIdentifier
/// - Pkcs5Pbkdf2.swift: PBKDF2 key derivation (RFC 8018 Section 5)
/// - Pkcs5Pbes2.swift: PBES2 encryption scheme (RFC 8018 Section 6)

import Foundation
import SwiftASN1

/// PKCS#5 password-based cryptography structures.
///
/// PKCS#5 provides:
/// - **PBKDF2**: Key derivation from passwords (see `Pkcs5Pbkdf2.swift`)
/// - **PBES2**: Password-based encryption scheme (see `Pkcs5Pbes2.swift`)
///
/// These are used together to encrypt/decrypt private keys with passwords.
///
/// ## Example
/// ```swift
/// // Decrypt an encrypted PKCS#8 private key
/// let decrypted = try encryptionScheme.decrypt(password: passwordData, document: encryptedData)
/// ```
internal enum Pkcs5 {

    // MARK: - Algorithm Identifier

    /// RFC 5280 algorithm identifier.
    ///
    /// An algorithm identifier pairs an OID with optional algorithm-specific parameters.
    /// This is a fundamental ASN.1 structure used throughout PKCS standards.
    ///
    /// ```text
    /// AlgorithmIdentifier ::= SEQUENCE {
    ///   algorithm    OBJECT IDENTIFIER,
    ///   parameters   ANY DEFINED BY algorithm OPTIONAL
    /// }
    /// ```
    internal struct AlgorithmIdentifier {
        /// The algorithm's object identifier (OID).
        internal let oid: ASN1ObjectIdentifier

        /// Optional algorithm-specific parameters encoded as ASN.1 ANY.
        internal let parameters: ASN1Any?

        /// Create an algorithm identifier.
        ///
        /// - Parameters:
        ///   - oid: The algorithm's object identifier.
        ///   - parameters: Optional algorithm-specific parameters.
        internal init(oid: ASN1ObjectIdentifier, parameters: ASN1Any? = nil) {
            self.oid = oid
            self.parameters = parameters
        }

        /// Extract the parameters as an OID, if applicable.
        ///
        /// Some algorithms use an OID as their parameter (e.g., named curves).
        internal var parametersOID: ASN1ObjectIdentifier? {
            try? parameters.map(ASN1ObjectIdentifier.init(asn1Any:))
        }
    }

    // MARK: - Encryption Scheme

    /// Supported encryption schemes for password-based encryption.
    ///
    /// Currently supports PBES2, which combines PBKDF2 key derivation
    /// with AES encryption.
    internal enum EncryptionScheme {
        /// PBES2 (Password-Based Encryption Scheme 2) with associated parameters.
        ///
        /// PBES2 uses PBKDF2 to derive a key from the password, then encrypts
        /// the data using a symmetric cipher (typically AES-CBC).
        case pbes2(Pbes2Parameters)

        /// Decrypt encrypted data using this encryption scheme.
        ///
        /// - Parameters:
        ///   - password: The password used to derive the encryption key.
        ///   - document: The encrypted data to decrypt.
        /// - Returns: The decrypted plaintext data.
        /// - Throws: An error if decryption fails (wrong password, corrupted data, etc.).
        internal func decrypt(password: Data, document: Data) throws -> Data {
            switch self {
            case .pbes2(let params):
                return try params.decrypt(password: password, document: document)
            }
        }
    }
}

// MARK: - AlgorithmIdentifier DER Conformance

extension Pkcs5.AlgorithmIdentifier: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (SEQUENCE).
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// Parses a SEQUENCE containing an OID and optional parameters.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: An error if the ASN.1 structure is invalid.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(derEncoded, identifier: identifier) { nodes in
            let oid = try ASN1ObjectIdentifier(derEncoded: &nodes)
            let parameters = nodes.next().map(ASN1Any.init(derEncoded:))
            return Self(oid: oid, parameters: parameters)
        }
    }

    /// Serialize to DER-encoded ASN.1 format.
    ///
    /// Writes a SEQUENCE containing the OID and optional parameters.
    ///
    /// - Parameters:
    ///   - coder: The serializer to write to.
    ///   - identifier: The ASN.1 identifier to use.
    /// - Throws: An error if serialization fails.
    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(oid)
            if let parameters = parameters {
                try coder.serialize(parameters)
            }
        }
    }
}

// MARK: - EncryptionScheme DER Conformance

extension Pkcs5.EncryptionScheme: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (same as AlgorithmIdentifier).
    internal static var defaultIdentifier: ASN1Identifier {
        Pkcs5.AlgorithmIdentifier.defaultIdentifier
    }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// Parses the algorithm identifier and extracts the PBES2 parameters.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: `ASN1Error.invalidASN1Object` if parsing fails or algorithm is unsupported.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        let algId = try Pkcs5.AlgorithmIdentifier(derEncoded: derEncoded, withIdentifier: identifier)

        guard let parameters = algId.parameters else {
            throw ASN1Error.invalidASN1Object
        }

        switch algId.oid {
        case .AlgorithmIdentifier.pbes2:
            self = .pbes2(try Pkcs5.Pbes2Parameters(asn1Any: parameters))
        default:
            throw ASN1Error.invalidASN1Object
        }
    }

    /// Serialize to DER-encoded ASN.1 format.
    ///
    /// - Parameters:
    ///   - coder: The serializer to write to.
    ///   - identifier: The ASN.1 identifier to use.
    /// - Throws: An error if serialization fails.
    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        let params: ASN1Any
        switch self {
        case .pbes2(let pbes2):
            params = try .init(erasing: pbes2)
        }

        try Pkcs5.AlgorithmIdentifier(oid: .AlgorithmIdentifier.pbes2, parameters: params)
            .serialize(into: &coder, withIdentifier: identifier)
    }
}
