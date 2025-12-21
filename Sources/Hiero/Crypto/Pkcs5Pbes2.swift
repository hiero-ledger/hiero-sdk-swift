// SPDX-License-Identifier: Apache-2.0

// MARK: - PBES2 (Password-Based Encryption Scheme 2)

/// PBES2 combines a key derivation function (KDF) with a symmetric encryption
/// scheme to encrypt data using a password. This is the modern standard for
/// password-based encryption, replacing the older PBES1.
///
/// Encryption process:
/// 1. Derive an encryption key from the password using KDF (PBKDF2)
/// 2. Encrypt the data using symmetric cipher (AES-CBC)
///
/// Decryption process:
/// 1. Re-derive the same key from the password using stored KDF parameters
/// 2. Decrypt the data using the derived key
///
/// This is used for encrypted PKCS#8 private keys.
///
/// Reference: RFC 8018 Section 6.2

import CryptoSwift
import Foundation
import SwiftASN1

// MARK: - PBES2 Types

extension Pkcs5 {

    // MARK: - Pbes2Parameters

    /// PBES2 (Password-Based Encryption Scheme 2) parameters.
    ///
    /// PBES2 combines:
    /// - A key derivation function (KDF) to derive a key from the password
    /// - An encryption scheme to encrypt/decrypt the data
    ///
    /// ```text
    /// PBES2-params ::= SEQUENCE {
    ///   keyDerivationFunc AlgorithmIdentifier {{PBES2-KDFs}},
    ///   encryptionScheme  AlgorithmIdentifier {{PBES2-Encs}} }
    /// ```
    ///
    /// ## Example
    /// ```swift
    /// // Decrypt encrypted data
    /// let plaintext = try pbes2Params.decrypt(password: passwordData, document: encryptedData)
    /// ```
    internal struct Pbes2Parameters {
        /// The key derivation function (e.g., PBKDF2).
        internal let kdf: Pbes2Kdf

        /// The encryption scheme (e.g., AES-128-CBC).
        internal let encryptionScheme: Pbes2EncryptionScheme

        /// Decrypt encrypted data using these PBES2 parameters.
        ///
        /// This method:
        /// 1. Derives an encryption key from the password using the KDF
        /// 2. Decrypts the document using the derived key
        ///
        /// - Parameters:
        ///   - password: The password used to derive the encryption key.
        ///   - document: The encrypted data to decrypt.
        /// - Returns: The decrypted plaintext.
        /// - Throws: An error if key derivation or decryption fails.
        internal func decrypt(password: Data, document: Data) throws -> Data {
            let derivedKey = try kdf.derive(password: password, keySize: encryptionScheme.keySize)
            return try encryptionScheme.decrypt(key: derivedKey, document: document)
        }
    }

    // MARK: - Pbes2Kdf

    /// Supported key derivation functions for PBES2.
    ///
    /// The KDF transforms a password into a cryptographic key of the
    /// appropriate size for the encryption scheme.
    internal enum Pbes2Kdf {
        /// PBKDF2 key derivation with associated parameters.
        ///
        /// PBKDF2 uses HMAC iteratively to derive a key, with the
        /// iteration count providing computational cost for attackers.
        case pbkdf2(Pbkdf2Parameters)

        // TODO: Consider adding scrypt support
        // case scrypt(ScryptParams)

        /// Derive a key using this KDF.
        ///
        /// - Parameters:
        ///   - password: The password to derive from.
        ///   - keySize: The desired key size in bytes.
        /// - Returns: The derived key.
        /// - Throws: An error if key derivation fails.
        internal func derive(password: Data, keySize: Int) throws -> Data {
            switch self {
            case .pbkdf2(let kdf):
                return try kdf.derive(password: password, keySize: keySize)
            }
        }
    }

    // MARK: - Pbes2EncryptionScheme

    /// Supported encryption schemes for PBES2.
    ///
    /// The encryption scheme specifies the symmetric cipher and mode
    /// used to encrypt the data after key derivation.
    internal enum Pbes2EncryptionScheme {
        /// AES-128 in CBC mode with PKCS#7 padding.
        ///
        /// The associated value is the 16-byte initialization vector (IV).
        /// The IV should be randomly generated for each encryption.
        ///
        /// ```text
        /// {OCTET STRING (SIZE(16)) IDENTIFIED BY aes128-CBC-PAD}
        /// ```
        case aes128Cbc(Data)

        /// The required key size in bytes for this encryption scheme.
        internal var keySize: Int {
            switch self {
            case .aes128Cbc:
                return 16  // 128 bits
            }
        }

        /// Decrypt data using this encryption scheme.
        ///
        /// - Parameters:
        ///   - key: The decryption key (must match `keySize`).
        ///   - document: The encrypted data.
        /// - Returns: The decrypted plaintext.
        /// - Throws: An error if decryption fails.
        internal func decrypt(key: Data, document: Data) throws -> Data {
            switch self {
            case .aes128Cbc(let iv):
                return try Aes.aes128CbcPadDecrypt(key: key, iv: iv, message: document)
            }
        }
    }
}

// MARK: - Pbes2Parameters DER Conformance

extension Pkcs5.Pbes2Parameters: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (SEQUENCE).
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: An error if the ASN.1 structure is invalid.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(derEncoded, identifier: identifier) { nodes in
            Self(
                kdf: try .init(derEncoded: &nodes),
                encryptionScheme: try .init(derEncoded: &nodes)
            )
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
            try kdf.serialize(into: &coder)
            try encryptionScheme.serialize(into: &coder)
        }
    }
}

// MARK: - Pbes2Kdf DER Conformance

extension Pkcs5.Pbes2Kdf: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (same as AlgorithmIdentifier).
    internal static var defaultIdentifier: ASN1Identifier {
        Pkcs5.AlgorithmIdentifier.defaultIdentifier
    }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// Parses the algorithm identifier and extracts the KDF parameters.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: `ASN1Error.invalidASN1Object` if parsing fails or KDF is unsupported.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        let algId = try Pkcs5.AlgorithmIdentifier(derEncoded: derEncoded, withIdentifier: identifier)

        guard let params = algId.parameters else {
            throw ASN1Error.invalidASN1Object
        }

        switch algId.oid {
        case .AlgorithmIdentifier.pbkdf2:
            self = .pbkdf2(try Pkcs5.Pbkdf2Parameters(asn1Any: params))
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
        let algId: Pkcs5.AlgorithmIdentifier
        switch self {
        case .pbkdf2(let params):
            algId = .init(oid: .AlgorithmIdentifier.pbkdf2, parameters: try .init(erasing: params))
        }
        try algId.serialize(into: &coder, withIdentifier: identifier)
    }
}

// MARK: - Pbes2EncryptionScheme DER Conformance

extension Pkcs5.Pbes2EncryptionScheme: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (same as AlgorithmIdentifier).
    internal static var defaultIdentifier: ASN1Identifier {
        Pkcs5.AlgorithmIdentifier.defaultIdentifier
    }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// Parses the algorithm identifier and extracts the encryption scheme parameters.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: `ASN1Error.invalidASN1Object` if parsing fails or scheme is unsupported.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        let algId = try Pkcs5.AlgorithmIdentifier(derEncoded: derEncoded, withIdentifier: identifier)

        guard let params = algId.parameters else {
            throw ASN1Error.invalidASN1Object
        }

        switch algId.oid {
        case .AlgorithmIdentifier.aes128CbcPad:
            let ivOctets = try ASN1OctetString(asn1Any: params)
            guard ivOctets.bytes.count == 16 else {
                throw ASN1Error.invalidASN1Object
            }
            self = .aes128Cbc(Data(ivOctets.bytes))
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
        let algId: Pkcs5.AlgorithmIdentifier
        switch self {
        case .aes128Cbc(let iv):
            algId = .init(
                oid: .AlgorithmIdentifier.aes128CbcPad,
                parameters: try .init(erasing: ASN1OctetString(contentBytes: Array(iv)[...]))
            )
        }
        try algId.serialize(into: &coder, withIdentifier: identifier)
    }
}

// MARK: - AES Decryption

/// Errors that can occur during AES operations.
internal enum AesError: Error {
    /// Decryption failed with the underlying error.
    case decryptionFailed(Error)
}

/// AES decryption using CBC mode with PKCS#7 padding.
///
/// Uses CryptoSwift for cross-platform compatibility (macOS + Linux).
internal enum Aes {
    /// Decrypt data using AES-128-CBC with PKCS#7 padding.
    ///
    /// - Parameters:
    ///   - key: The 16-byte decryption key (derived via PBKDF2).
    ///   - iv: The 16-byte initialization vector.
    ///   - message: The encrypted data.
    /// - Returns: The decrypted data.
    /// - Throws: `AesError.decryptionFailed` if decryption fails.
    internal static func aes128CbcPadDecrypt(key: Data, iv: Data, message: Data) throws -> Data {
        precondition(key.count == 16, "bug: key size \(key.count) incorrect for AES-128")
        precondition(iv.count == 16, "bug: iv size incorrect for AES-128")

        do {
            let aes = try AES(key: Array(key), blockMode: CBC(iv: Array(iv)), padding: .pkcs7)
            return Data(try aes.decrypt(Array(message)))
        } catch {
            throw AesError.decryptionFailed(error)
        }
    }
}
