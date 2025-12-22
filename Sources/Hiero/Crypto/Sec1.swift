// SPDX-License-Identifier: Apache-2.0

/// SEC1 (Standards for Efficient Cryptography 1) defines the format for
/// elliptic curve private keys. This is used in PEM files with the
/// "EC PRIVATE KEY" type label.
///
/// SEC1 is an older format that includes:
/// - The private key value (big-endian integer)
/// - Optional curve parameters (typically a named curve OID)
/// - Optional public key point
///
/// Modern applications typically use PKCS#8 wrapping SEC1 keys, but
/// standalone SEC1 keys are still common.
///
/// Reference: https://www.secg.org/sec1-v2.pdf

import Foundation
import SwiftASN1

/// SEC1 elliptic curve key structures.
///
/// SEC1 provides the ASN.1 format for EC private keys, commonly used
/// in PEM files with the "EC PRIVATE KEY" header.
///
/// ## Example
/// ```swift
/// // Parse SEC1 key from DER
/// let ecKey = try Sec1.ECPrivateKey(derEncoded: derData)
///
/// // Access the raw private key bytes
/// let keyBytes = Data(ecKey.privateKey.bytes)
///
/// // Check which curve is used
/// if ecKey.parameters?.namedCurve == .NamedCurves.secp256k1 {
///     // Handle secp256k1 key
/// }
/// ```
internal enum Sec1 {

    // MARK: - ECPrivateKey

    /// SEC1 EC private key structure.
    ///
    /// This is the main structure for SEC1-encoded elliptic curve private keys.
    ///
    /// ```text
    /// ECPrivateKey ::= SEQUENCE {
    ///   version        INTEGER { ecPrivkeyVer1(1) } (ecPrivkeyVer1),
    ///   privateKey     OCTET STRING,
    ///   parameters [0] ECParameters {{ NamedCurve }} OPTIONAL,
    ///   publicKey  [1] BIT STRING OPTIONAL
    /// }
    /// ```
    internal struct ECPrivateKey {
        /// The raw private key bytes (big-endian integer).
        ///
        /// For secp256k1, this is a 32-byte value.
        internal let privateKey: ASN1OctetString

        /// Optional curve parameters.
        ///
        /// When present, identifies the elliptic curve (e.g., secp256k1).
        /// May be omitted if the curve is implied by context.
        internal let parameters: EcParameters?

        /// Optional public key point.
        ///
        /// When present, contains the uncompressed public key point
        /// (typically 65 bytes: 0x04 prefix + 32-byte X + 32-byte Y).
        internal let publicKey: ASN1BitString?

        /// Create a SEC1 EC private key structure.
        ///
        /// - Parameters:
        ///   - privateKey: The raw private key bytes.
        ///   - parameters: Optional curve identification.
        ///   - publicKey: Optional public key point.
        internal init(
            privateKey: ASN1OctetString,
            parameters: EcParameters?,
            publicKey: ASN1BitString? = nil
        ) {
            self.privateKey = privateKey
            self.parameters = parameters
            self.publicKey = publicKey
        }

        /// The SEC1 version number (always v1).
        fileprivate var version: Version { .v1 }
    }

    // MARK: - EcParameters

    /// Elliptic curve parameters.
    ///
    /// SEC1 supports multiple ways to specify curve parameters, but in practice
    /// only named curves (identified by OID) are commonly used.
    internal enum EcParameters {
        /// A named curve identified by its OID.
        ///
        /// Common curves:
        /// - secp256k1 (Bitcoin, Ethereum, Hedera)
        /// - secp256r1/prime256v1/P-256 (general purpose)
        case namedCurve(ASN1ObjectIdentifier)

        /// Extract the OID if this is a named curve.
        var namedCurve: ASN1ObjectIdentifier? {
            if case .namedCurve(let oid) = self {
                return oid
            }
            return nil
        }
    }

    // MARK: - Version (Internal)

    /// SEC1 version number.
    ///
    /// ```text
    /// INTEGER { ecPrivkeyVer1(1) } (ecPrivkeyVer1)
    /// ```
    fileprivate enum Version: Int, Equatable {
        /// Version 1: The only defined version for SEC1 EC private keys.
        case v1 = 1
    }
}

// MARK: - ECPrivateKey DER Conformance

extension Sec1.ECPrivateKey: DERImplicitlyTaggable {
    /// Tag number for the optional parameters field.
    internal static let parametersTagNumber: UInt = 0

    /// Tag number for the optional public key field.
    internal static let publicKeyTagNumber: UInt = 1

    /// The default ASN.1 identifier (SEQUENCE).
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// Parses the SEC1 ECPrivateKey structure.
    ///
    /// - Parameters:
    ///   - rootNode: The DER-encoded ASN.1 node.
    ///   - identifier: The expected ASN.1 identifier.
    /// - Throws: `ASN1Error.invalidASN1Object` if parsing fails or version is unsupported.
    internal init(derEncoded rootNode: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(rootNode, identifier: identifier) { nodes in
            let version = try Sec1.Version(derEncoded: &nodes)

            switch version {
            case .v1: break
            }

            let privateKey = try ASN1OctetString(derEncoded: &nodes)

            let parameters = try DER.optionalExplicitlyTagged(
                &nodes,
                tagNumber: Self.parametersTagNumber,
                tagClass: .contextSpecific,
                Sec1.EcParameters.init(derEncoded:)
            )

            let publicKey = try DER.optionalExplicitlyTagged(
                &nodes,
                tagNumber: Self.publicKeyTagNumber,
                tagClass: .contextSpecific,
                ASN1BitString.init(derEncoded:)
            )

            return Self(privateKey: privateKey, parameters: parameters, publicKey: publicKey)
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
            try coder.serialize(privateKey)

            if let parameters = parameters {
                try coder.serialize(
                    parameters,
                    explicitlyTaggedWithTagNumber: Self.parametersTagNumber,
                    tagClass: .contextSpecific
                )
            }

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

// MARK: - EcParameters DER Conformance

extension Sec1.EcParameters: DERSerializable, DERParseable {
    /// Initialize from DER-encoded ASN.1 data.
    ///
    /// Only named curves (OID-based identification) are supported.
    ///
    /// - Parameter derEncoded: The DER-encoded ASN.1 node.
    /// - Throws: An error if parsing fails.
    internal init(derEncoded: ASN1Node) throws {
        self = try .namedCurve(ASN1ObjectIdentifier(derEncoded: derEncoded))
    }

    /// Serialize to DER-encoded ASN.1 format.
    ///
    /// - Parameter coder: The serializer to write to.
    /// - Throws: An error if serialization fails.
    internal func serialize(into coder: inout DER.Serializer) throws {
        switch self {
        case .namedCurve(let oid):
            try oid.serialize(into: &coder)
        }
    }
}

// MARK: - Version DER Conformance

extension Sec1.Version: DERImplicitlyTaggable {
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
