// SPDX-License-Identifier: Apache-2.0

import CommonCrypto
import CryptoKit
import Foundation
import SwiftASN1

internal enum Pkcs5 {}

extension Pkcs5 {
    internal enum EncryptionScheme {
        case pbes2(Pbes2Parameters)
    }
}

extension ASN1ObjectIdentifier.NamedCurves {
    /// OID for the secp256k1 named curve.
    ///
    /// `iso(1) identified-organization(3) certicom(132) curve(0) 10`
    internal static let secp256k1: ASN1ObjectIdentifier = [1, 3, 132, 0, 10]
}

extension ASN1ObjectIdentifier.AlgorithmIdentifier {
    /// OID for the ed25519 algorithm.
    ///
    /// `iso(1) identified-organization(3) thawte(101) id-Ed25519(112)`
    ///
    /// `101.100` through `101.127` were donated to the IETF Curdle Security Working Group for the sake of Edwards Elliptic Curves with smaller arcs, hence the weird spot.
    internal static let ed25519: ASN1ObjectIdentifier = [1, 3, 101, 112]

    /// OID for the password based key derivation function version 2 (PBKDF2) algorithm.
    ///
    /// `iso(1) member-body(2) us(840) rsadsi(113549) pkcs(1) pkcs-5(5) id-PBKDF2(12)`
    internal static let pbkdf2: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 1, 5, 12]

    /// OID for the password based key derivation function version 2 (PBKDF2) algorithm.
    ///
    /// `iso(1) member-body(2) us(840) rsadsi(113549) pkcs(1) pkcs-5(5) id-PBES2(13)`
    internal static let pbes2: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 1, 5, 13]

    /// OID for AES 128 bit encryption in CBC mode with RFC-5652 padding.
    ///
    /// `joint-iso-itu-t(2).country(16).us(840).organization(1).gov(101).csor(3).nistAlgorithms(4).aes(1).aes128-CBC-PAD(2)`
    internal static let aes128CbcPad: ASN1ObjectIdentifier = [2, 16, 840, 1, 101, 3, 4, 1, 2]
}

extension Pkcs5.EncryptionScheme {
    internal func decrypt(password: Data, document: Data) throws -> Data {
        switch self {
        case .pbes2(let params): return try params.decrypt(password: password, document: document)
        }
    }
}

extension Pkcs5.EncryptionScheme: DERImplicitlyTaggable {
    internal static var defaultIdentifier: ASN1Identifier {
        Pkcs5.AlgorithmIdentifier.defaultIdentifier
    }

    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        let algId = try Pkcs5.AlgorithmIdentifier(derEncoded: derEncoded, withIdentifier: identifier)

        guard let parameters = algId.parameters else {
            throw ASN1Error.invalidASN1Object(reason: "HMAC algorithm requires NULL parameters")
        }

        switch algId.oid {
        case .AlgorithmIdentifier.pbes2:
            self = .pbes2(try Pkcs5.Pbes2Parameters(asn1Any: parameters))
        default:
            throw ASN1Error.invalidASN1Object(reason: "unsupported algorithm identifier: \(algId.oid)")
        }
    }

    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        let params: ASN1Any
        switch self {
        case .pbes2(let pbes2):
            params = try .init(erasing: pbes2)
        }

        return try Pkcs5.AlgorithmIdentifier(oid: .AlgorithmIdentifier.pbes2, parameters: params)
            .serialize(into: &coder, withIdentifier: identifier)
    }
}
