// SPDX-License-Identifier: Apache-2.0

// MARK: - ASN.1 Object Identifiers (OIDs)

/// This file defines ASN.1 Object Identifiers used for cryptographic key encoding.
/// OIDs are hierarchical identifiers that uniquely identify algorithms, curves,
/// and other cryptographic constructs in ASN.1/DER-encoded data.
///
/// OID paths follow the ISO/ITU-T hierarchical naming structure.
/// Example: `1.2.840.113549.1.5.12` = iso(1).member-body(2).us(840).rsadsi(113549).pkcs(1).pkcs-5(5).id-PBKDF2(12)

import SwiftASN1

// MARK: - Named Curves

extension ASN1ObjectIdentifier.NamedCurves {
    /// OID for the secp256k1 elliptic curve.
    ///
    /// Used by Bitcoin, Ethereum, and Hedera for ECDSA signatures.
    ///
    /// Path: `iso(1).identified-organization(3).certicom(132).curve(0).secp256k1(10)`
    internal static let secp256k1: ASN1ObjectIdentifier = [1, 3, 132, 0, 10]
}

// MARK: - Algorithm Identifiers

extension ASN1ObjectIdentifier.AlgorithmIdentifier {
    /// OID for the Ed25519 signature algorithm.
    ///
    /// Used by Hedera for EdDSA signatures on Curve25519.
    ///
    /// Path: `iso(1).identified-organization(3).thawte(101).id-Ed25519(112)`
    internal static let ed25519: ASN1ObjectIdentifier = [1, 3, 101, 112]

    /// OID for PBKDF2 (Password-Based Key Derivation Function 2).
    ///
    /// Used to derive encryption keys from passwords.
    ///
    /// Path: `iso(1).member-body(2).us(840).rsadsi(113549).pkcs(1).pkcs-5(5).id-PBKDF2(12)`
    internal static let pbkdf2: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 1, 5, 12]

    /// OID for PBES2 (Password-Based Encryption Scheme 2).
    ///
    /// The modern password-based encryption standard from PKCS#5.
    ///
    /// Path: `iso(1).member-body(2).us(840).rsadsi(113549).pkcs(1).pkcs-5(5).id-PBES2(13)`
    internal static let pbes2: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 1, 5, 13]

    /// OID for AES-128-CBC with PKCS#7 padding.
    ///
    /// Used as the symmetric cipher in PBES2.
    ///
    /// Path: `joint-iso-itu-t(2).country(16).us(840).organization(1).gov(101).csor(3).nistAlgorithms(4).aes(1).aes128-CBC-PAD(2)`
    internal static let aes128CbcPad: ASN1ObjectIdentifier = [2, 16, 840, 1, 101, 3, 4, 1, 2]
}

// MARK: - Digest Algorithm Identifiers

extension ASN1ObjectIdentifier {
    /// OIDs for HMAC digest algorithms used in PBKDF2.
    internal enum DigestAlgorithm {
        /// HMAC-SHA-1 digest algorithm.
        ///
        /// - Warning: SHA-1 is deprecated for security purposes. Use SHA-256 or higher.
        ///
        /// Path: `iso(1).member-body(2).us(840).rsadsi(113549).digestAlgorithm(2).hmacWithSHA1(7)`
        internal static let hmacWithSha1: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 7]

        /// HMAC-SHA-224 digest algorithm.
        ///
        /// Path: `iso(1).member-body(2).us(840).rsadsi(113549).digestAlgorithm(2).hmacWithSHA224(8)`
        internal static let hmacWithSha224: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 8]

        /// HMAC-SHA-256 digest algorithm.
        ///
        /// Recommended for most PBKDF2 uses.
        ///
        /// Path: `iso(1).member-body(2).us(840).rsadsi(113549).digestAlgorithm(2).hmacWithSHA256(9)`
        internal static let hmacWithSha256: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 9]

        /// HMAC-SHA-384 digest algorithm.
        ///
        /// Path: `iso(1).member-body(2).us(840).rsadsi(113549).digestAlgorithm(2).hmacWithSHA384(10)`
        internal static let hmacWithSha384: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 10]

        /// HMAC-SHA-512 digest algorithm.
        ///
        /// Path: `iso(1).member-body(2).us(840).rsadsi(113549).digestAlgorithm(2).hmacWithSHA512(11)`
        internal static let hmacWithSha512: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 11]
    }
}
