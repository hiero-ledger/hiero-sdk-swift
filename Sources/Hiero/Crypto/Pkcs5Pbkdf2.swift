// SPDX-License-Identifier: Apache-2.0

// MARK: - PBKDF2 (Password-Based Key Derivation Function 2)

/// PBKDF2 derives a cryptographic key from a password using a pseudorandom
/// function (typically HMAC) applied iteratively. The iteration count and
/// salt provide protection against brute-force attacks.
///
/// Security considerations:
/// - Higher iteration counts = slower attacks but slower legitimate use
/// - Salt prevents rainbow table attacks
/// - Use a cryptographically random salt of at least 16 bytes
///
/// Used for:
/// - Deriving encryption keys from passwords (PBES2)
/// - Mnemonic seed generation (BIP-39)
/// - Legacy key derivation
///
/// Reference: RFC 8018 Section 5.2

import CryptoSwift
import Foundation
import SwiftASN1

// MARK: - PBKDF2 Types

extension Pkcs5 {

    // MARK: - Pbkdf2Parameters

    /// PBKDF2 parameters as defined in RFC 8018.
    ///
    /// These parameters control how a password is transformed into a
    /// cryptographic key:
    ///
    /// ```text
    /// PBKDF2-params ::= SEQUENCE {
    ///   salt CHOICE {
    ///       specified OCTET STRING,
    ///       otherSource AlgorithmIdentifier {{PBKDF2-SaltSources}}
    ///   },
    ///   iterationCount INTEGER (1..MAX),
    ///   keyLength INTEGER (1..MAX) OPTIONAL,
    ///   prf AlgorithmIdentifier {{PBKDF2-PRFs}} DEFAULT algid-hmacWithSHA1 }
    /// ```
    ///
    /// ## Example
    /// ```swift
    /// let params = Pkcs5.Pbkdf2Parameters(
    ///     salt: randomSalt,
    ///     iterationCount: 100_000,
    ///     keyLength: nil,
    ///     prf: .hmacWithSha256
    /// )
    /// let derivedKey = try params.derive(password: passwordData, keySize: 32)
    /// ```
    internal struct Pbkdf2Parameters {
        // MARK: Constants

        /// Maximum allowed iteration count (10 million) to prevent DoS attacks.
        internal static let maxIterations: UInt32 = 10_000_000

        // MARK: Properties

        /// Random salt value to prevent rainbow table attacks.
        ///
        /// Should be at least 16 bytes of cryptographically random data.
        internal let salt: Data

        /// Number of HMAC iterations to perform.
        ///
        /// Higher values provide more security but slower derivation.
        /// Common values: 10,000 to 100,000 for interactive use.
        internal let iterationCount: UInt32

        /// Optional explicit key length in bytes.
        ///
        /// If not specified, the key length is determined by usage context.
        internal let keyLength: UInt16?

        /// The pseudorandom function (HMAC variant) to use.
        ///
        /// Defaults to HMAC-SHA-1 for compatibility, but HMAC-SHA-256
        /// or higher is recommended for new implementations.
        internal let prf: Pbkdf2Prf

        // MARK: Initialization

        /// Create PBKDF2 parameters.
        ///
        /// - Parameters:
        ///   - salt: Random salt value (at least 16 bytes recommended).
        ///   - iterationCount: Number of iterations (1 to 10,000,000).
        ///   - keyLength: Optional explicit key length.
        ///   - prf: The PRF to use (defaults to HMAC-SHA-1).
        /// - Returns: `nil` if iteration count is out of range or keyLength is 0.
        internal init?(
            salt: Data,
            iterationCount: UInt32,
            keyLength: UInt16?,
            prf: Pbkdf2Prf = .hmacWithSha1
        ) {
            guard (1...Self.maxIterations).contains(iterationCount) else { return nil }
            if let keyLength, keyLength < 1 { return nil }
            self.salt = salt
            self.iterationCount = iterationCount
            self.keyLength = keyLength
            self.prf = prf
        }

        // MARK: Key Derivation

        /// Derive a cryptographic key from a password using these PBKDF2 parameters.
        ///
        /// - Parameters:
        ///   - password: The password to derive the key from.
        ///   - keySize: The desired key size in bytes.
        /// - Returns: The derived key.
        /// - Throws: `HError.keyParse` if keyLength doesn't match keySize.
        internal func derive(password: Data, keySize: Int) throws -> Data {
            if let keyLength = self.keyLength, Int(keyLength) != keySize {
                throw HError.keyParse("invalid algorithm parameters")
            }

            let pbkdf2 = try PKCS5.PBKDF2(
                password: Array(password),
                salt: Array(salt),
                iterations: Int(iterationCount),
                keyLength: keySize,
                variant: prf.hmacVariant
            )
            return Data(try pbkdf2.calculate())
        }
    }

    // MARK: - Pbkdf2Prf

    /// Supported HMAC pseudorandom functions for PBKDF2.
    ///
    /// The PRF is the hash function used in each iteration of PBKDF2.
    /// Stronger hash functions provide better security.
    internal enum Pbkdf2Prf {
        /// HMAC with SHA-1 (160-bit, legacy default).
        case hmacWithSha1
        /// HMAC with SHA-224 (224-bit).
        case hmacWithSha224
        /// HMAC with SHA-256 (256-bit, recommended).
        case hmacWithSha256
        /// HMAC with SHA-384 (384-bit).
        case hmacWithSha384
        /// HMAC with SHA-512 (512-bit, strongest).
        case hmacWithSha512

        /// The ASN.1 object identifier for this PRF variant.
        internal var oid: ASN1ObjectIdentifier {
            switch self {
            case .hmacWithSha1: return .DigestAlgorithm.hmacWithSha1
            case .hmacWithSha224: return .DigestAlgorithm.hmacWithSha224
            case .hmacWithSha256: return .DigestAlgorithm.hmacWithSha256
            case .hmacWithSha384: return .DigestAlgorithm.hmacWithSha384
            case .hmacWithSha512: return .DigestAlgorithm.hmacWithSha512
            }
        }

        /// The CryptoSwift HMAC variant for this PRF.
        internal var hmacVariant: CryptoSwift.HMAC.Variant {
            switch self {
            case .hmacWithSha1: return .sha1
            case .hmacWithSha224: return .sha2(.sha224)
            case .hmacWithSha256: return .sha2(.sha256)
            case .hmacWithSha384: return .sha2(.sha384)
            case .hmacWithSha512: return .sha2(.sha512)
            }
        }
    }

    // MARK: - Standalone PBKDF2 Helper

    /// Derive a key using PBKDF2 with the specified parameters.
    ///
    /// This is a convenience method for direct PBKDF2 derivation without
    /// constructing `Pbkdf2Parameters`. Useful for non-PKCS#5 contexts
    /// like BIP-39 mnemonic seed generation.
    ///
    /// ## Example
    /// ```swift
    /// let seed = Pkcs5.pbkdf2(
    ///     sha: .sha512,
    ///     password: mnemonicData,
    ///     salt: "mnemonic" + passphrase,
    ///     rounds: 2048,
    ///     keySize: 64
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - sha: The SHA-2 variant to use for HMAC.
    ///   - password: The password to derive from.
    ///   - salt: The salt value.
    ///   - rounds: Number of iterations.
    ///   - keySize: Desired key size in bytes.
    /// - Returns: The derived key.
    internal static func pbkdf2(
        sha: Sha2,
        password: Data,
        salt: Data,
        rounds: UInt32,
        keySize: Int
    ) -> Data {
        let variant: CryptoSwift.HMAC.Variant
        switch sha {
        case .sha256: variant = .sha2(.sha256)
        case .sha384: variant = .sha2(.sha384)
        case .sha512: variant = .sha2(.sha512)
        }
        // swiftlint:disable:next force_try
        let kdf = try! PKCS5.PBKDF2(
            password: Array(password),
            salt: Array(salt),
            iterations: Int(rounds),
            keyLength: keySize,
            variant: variant
        )
        // swiftlint:disable:next force_try
        return Data(try! kdf.calculate())
    }
}

// MARK: - Pbkdf2Parameters DER Conformance

extension Pkcs5.Pbkdf2Parameters: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (SEQUENCE).
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// Parses the PBKDF2-params structure containing salt, iteration count,
    /// optional key length, and PRF.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: `ASN1Error.invalidASN1Object` if parsing fails or parameters are invalid.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(derEncoded, identifier: identifier) { nodes in
            let salt = try ASN1OctetString(derEncoded: &nodes)
            let iterationCount = try UInt32(derEncoded: &nodes)
            let keyLength: UInt16? = try DER.optionalImplicitlyTagged(&nodes)
            let prf = try DER.decodeDefault(&nodes, defaultValue: Pkcs5.Pbkdf2Prf.hmacWithSha1)

            guard
                let value = Self(
                    salt: Data(salt.bytes),
                    iterationCount: iterationCount,
                    keyLength: keyLength,
                    prf: prf
                )
            else {
                throw ASN1Error.invalidASN1Object
            }
            return value
        }
    }

    /// Serialize to DER-encoded ASN.1 format.
    ///
    /// Writes the PBKDF2-params structure. Key length is omitted if nil,
    /// and PRF is omitted if it's the default (HMAC-SHA-1).
    ///
    /// - Parameters:
    ///   - coder: The serializer to write to.
    ///   - identifier: The ASN.1 identifier to use.
    /// - Throws: An error if serialization fails.
    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: .sequence) { coder in
            try coder.serialize(ASN1OctetString(contentBytes: Array(self.salt)[...]))
            try coder.serialize(iterationCount)
            if let keyLength { try coder.serialize(keyLength) }
            if prf != .hmacWithSha1 { try coder.serialize(prf) }
        }
    }
}

// MARK: - Pbkdf2Prf DER Conformance

extension Pkcs5.Pbkdf2Prf: DERImplicitlyTaggable {
    /// The default ASN.1 identifier (SEQUENCE, as AlgorithmIdentifier).
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// Parses an AlgorithmIdentifier and maps the OID to the corresponding PRF.
    ///
    /// - Parameters:
    ///   - derEncoded: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: `ASN1Error.invalidASN1Object` if the PRF is unsupported.
    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        let algId = try Pkcs5.AlgorithmIdentifier(derEncoded: derEncoded, withIdentifier: identifier)
        guard let params = algId.parameters else { throw ASN1Error.invalidASN1Object }
        _ = try ASN1Null(asn1Any: params)

        switch algId.oid {
        case .DigestAlgorithm.hmacWithSha1: self = .hmacWithSha1
        case .DigestAlgorithm.hmacWithSha224: self = .hmacWithSha224
        case .DigestAlgorithm.hmacWithSha256: self = .hmacWithSha256
        case .DigestAlgorithm.hmacWithSha384: self = .hmacWithSha384
        case .DigestAlgorithm.hmacWithSha512: self = .hmacWithSha512
        default: throw ASN1Error.invalidASN1Object
        }
    }

    /// Serialize to DER-encoded ASN.1 format.
    ///
    /// - Parameters:
    ///   - coder: The serializer to write to.
    ///   - identifier: The ASN.1 identifier to use (ignored, uses default).
    /// - Throws: An error if serialization fails.
    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try Pkcs5.AlgorithmIdentifier(oid: self.oid).serialize(into: &coder)
    }
}
