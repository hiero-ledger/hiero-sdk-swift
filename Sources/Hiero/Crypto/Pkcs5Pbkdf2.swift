// SPDX-License-Identifier: Apache-2.0

import CryptoSwift
import Foundation
import SwiftASN1

// MARK: - PRF enum (declare first so it's in scope for Pbkdf2Parameters)

extension Pkcs5 {
    /// Supported HMAC PRFs for PBKDF2.
    internal enum Pbkdf2Prf {
        case hmacWithSha1
        case hmacWithSha224
        case hmacWithSha256
        case hmacWithSha384
        case hmacWithSha512
    }
}

extension ASN1ObjectIdentifier {
    internal enum DigestAlgorithm {
        internal static let hmacWithSha1: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 7]
        internal static let hmacWithSha224: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 8]
        internal static let hmacWithSha256: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 9]
        internal static let hmacWithSha384: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 10]
        internal static let hmacWithSha512: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 2, 11]
    }
}

extension Pkcs5.Pbkdf2Prf {
    internal var oid: ASN1ObjectIdentifier {
        switch self {
        case .hmacWithSha1: return .DigestAlgorithm.hmacWithSha1
        case .hmacWithSha224: return .DigestAlgorithm.hmacWithSha224
        case .hmacWithSha256: return .DigestAlgorithm.hmacWithSha256
        case .hmacWithSha384: return .DigestAlgorithm.hmacWithSha384
        case .hmacWithSha512: return .DigestAlgorithm.hmacWithSha512
        }
    }

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

extension Pkcs5.Pbkdf2Prf: DERImplicitlyTaggable {
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

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

    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try Pkcs5.AlgorithmIdentifier(oid: self.oid).serialize(into: &coder)
    }
}

// MARK: - PBKDF2 parameters

extension Pkcs5 {
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
    internal struct Pbkdf2Parameters {
        internal static let maxIterations: UInt32 = 10_000_000

        internal let salt: Data
        internal let iterationCount: UInt32
        internal let keyLength: UInt16?
        internal let prf: Pbkdf2Prf

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
    }
}

extension Pkcs5.Pbkdf2Parameters: DERImplicitlyTaggable {
    internal static var defaultIdentifier: ASN1Identifier { .sequence }

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

    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: .sequence) { coder in
            try coder.serialize(ASN1OctetString(contentBytes: Array(self.salt)[...]))
            try coder.serialize(iterationCount)
            if let keyLength { try coder.serialize(keyLength) }
            if prf != .hmacWithSha1 { try coder.serialize(prf) }
        }
    }
}

// MARK: - Derivation (CryptoSwift)

extension Pkcs5.Pbkdf2Parameters {
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

// MARK: - Back-compat helper used by PrivateKey.swift

extension Pkcs5 {
    internal static func pbkdf2(
        variant: CryptoNamespace.Hmac,
        password: Data,
        salt: Data,
        rounds: UInt32,
        keySize: Int
    ) -> Data {
        let v: CryptoSwift.HMAC.Variant
        switch variant {
        case .sha2(.sha256): v = .sha2(.sha256)
        case .sha2(.sha384): v = .sha2(.sha384)
        case .sha2(.sha512): v = .sha2(.sha512)
        }
        let kdf = try! PKCS5.PBKDF2(
            password: Array(password),
            salt: Array(salt),
            iterations: Int(rounds),
            keyLength: keySize,
            variant: v
        )
        return Data(try! kdf.calculate())
    }
}
