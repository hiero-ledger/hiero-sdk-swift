// SPDX-License-Identifier: Apache-2.0

import Foundation
import SwiftASN1

internal enum Pkcs5 {}

extension Pkcs5 {
    /// ```text
    /// PBES2-params ::= SEQUENCE {
    ///   keyDerivationFunc AlgorithmIdentifier {{PBES2-KDFs}},
    ///   encryptionScheme  AlgorithmIdentifier {{PBES2-Encs}} }
    /// ```
    internal struct Pbes2Parameters {
        internal let kdf: Pbes2Kdf
        internal let encryptionScheme: Pbes2EncryptionScheme
    }

    internal enum Pbes2Kdf {
        case pbkdf2(Pbkdf2Parameters)
        // TODO: support scrypt?
        // case scrypt(ScryptParams)
    }

    internal enum Pbes2EncryptionScheme {
        /// The parameters field for this OID is `OCTET STRING (SIZE(16))`
        /// containing the IV for CBC mode.
        /// `{OCTET STRING (SIZE(16)) IDENTIFIED BY aes128-CBC-PAD}`
        case aes128Cbc(Data)  // iv
    }
}

extension ASN1ObjectIdentifier.NamedCurves {
    /// OID for the secp256k1 named curve.
    /// `1.3.132.0.10`
    internal static let secp256k1: ASN1ObjectIdentifier = [1, 3, 132, 0, 10]
}

extension ASN1ObjectIdentifier.AlgorithmIdentifier {
    /// OID for Ed25519.
    /// `1.3.101.112`
    internal static let ed25519: ASN1ObjectIdentifier = [1, 3, 101, 112]

    /// OID for PBKDF2.
    /// `1.2.840.113549.1.5.12`
    internal static let pbkdf2: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 1, 5, 12]

    /// OID for PBES2.
    /// `1.2.840.113549.1.5.13`
    internal static let pbes2: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 1, 5, 13]

    /// OID for AES-128-CBC with RFC-5652 padding.
    /// `2.16.840.1.101.3.4.1.2`
    internal static let aes128CbcPad: ASN1ObjectIdentifier = [2, 16, 840, 1, 101, 3, 4, 1, 2]
}

extension Pkcs5.EncryptionScheme {
    internal func decrypt(password: Data, document: Data) throws -> Data {
        switch self {
        case .pbes2(let params):
            return try params.decrypt(password: password, document: document)
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
            throw ASN1Error.invalidASN1Object
        }

        switch algId.oid {
        case .AlgorithmIdentifier.pbes2:
            self = .pbes2(try Pkcs5.Pbes2Parameters(asn1Any: parameters))
        default:
            throw ASN1Error.invalidASN1Object
        }
    }

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

extension Pkcs5.Pbes2Kdf: DERImplicitlyTaggable {
    internal static var defaultIdentifier: ASN1Identifier {
        Pkcs5.AlgorithmIdentifier.defaultIdentifier
    }

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

    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        let algId: Pkcs5.AlgorithmIdentifier
        switch self {
        case .pbkdf2(let params):
            algId = .init(oid: .AlgorithmIdentifier.pbkdf2, parameters: try .init(erasing: params))
        }
        try algId.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension Pkcs5.Pbes2Kdf {
    internal func derive(password: Data, keySize: Int) throws -> Data {
        switch self {
        case .pbkdf2(let kdf):
            return try kdf.derive(password: password, keySize: keySize)
        }
    }
}

extension Pkcs5.Pbes2EncryptionScheme: DERImplicitlyTaggable {
    internal static var defaultIdentifier: ASN1Identifier {
        Pkcs5.AlgorithmIdentifier.defaultIdentifier
    }

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

extension Pkcs5.Pbes2EncryptionScheme {
    internal var keySize: Int {
        switch self {
        case .aes128Cbc:
            return 16
        }
    }

    internal func decrypt(key: Data, document: Data) throws -> Data {
        switch self {
        // note: the 128 here refers to the key size
        case .aes128Cbc(let iv):
            // Use cross-platform AES shim (CommonCrypto on Apple, CryptoSwift on Linux)
            return try CryptoAES.aes128CbcPadDecrypt(key: key, iv: iv, message: document)
        }
    }
}

extension Pkcs5.Pbes2Parameters: DERImplicitlyTaggable {
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(derEncoded, identifier: identifier) { nodes in
            Self(
                kdf: try .init(derEncoded: &nodes),
                encryptionScheme: try .init(derEncoded: &nodes)
            )
        }
    }

    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try kdf.serialize(into: &coder)
            try encryptionScheme.serialize(into: &coder)
        }
    }
}

extension Pkcs5.Pbes2Parameters {
    internal func decrypt(password: Data, document: Data) throws -> Data {
        let derivedKey = try kdf.derive(password: password, keySize: encryptionScheme.keySize)
        return try encryptionScheme.decrypt(key: derivedKey, document: document)
    }
}
