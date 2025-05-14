// SPDX-License-Identifier: Apache-2.0

import CommonCrypto
import Foundation
import SwiftASN1

extension Pkcs5 {
    internal static func pbkdf2(
        variant: Crypto.Hmac,
        password: Data,
        salt: Data,
        rounds: UInt32,
        keySize: Int
    ) -> Data {

        let prf: CCPBKDFAlgorithm
        switch variant {
        case .sha2(.sha256): prf = CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256)
        case .sha2(.sha384): prf = CCPBKDFAlgorithm(kCCPRFHmacAlgSHA384)
        case .sha2(.sha512): prf = CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512)
        }

        return pbkdf2(prf: prf, password: password, salt: salt, rounds: rounds, keySize: keySize)
    }

    private static func pbkdf2(
        prf: CCPBKDFAlgorithm,
        password: Data,
        salt: Data,
        rounds: UInt32,
        keySize: Int
    ) -> Data {
        var derivedKey = Data(repeating: 0, count: keySize)

        let status = derivedKey.withUnsafeMutableTypedBytes { derivedKey in
            password.withUnsafeTypedBytes { password in
                salt.withUnsafeTypedBytes { salt in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        password.baseAddress,
                        password.count,
                        salt.baseAddress,
                        salt.count,
                        prf,
                        rounds,
                        derivedKey.baseAddress,
                        derivedKey.count
                    )
                }
            }
        }

        // an error here should be unreachable when it comes to hmac.
        precondition(status == 0, "pbkdf2 hmac failed with status: \(status)")

        return derivedKey
    }

    /// ```text
    /// PBKDF2-params ::= SEQUENCE {
    ///   salt CHOICE {
    ///       specified OCTET STRING,
    ///       otherSource AlgorithmIdentifier {{PBKDF2-SaltSources}}
    ///   },
    ///   iterationCount INTEGER (1..MAX),
    ///   keyLength INTEGER (1..MAX) OPTIONAL,
    ///   prf AlgorithmIdentifier {{PBKDF2-PRFs}} DEFAULT
    ///   algid-hmacWithSHA1 }
    /// ```
    internal struct Pbkdf2Parameters {
        /// Make PBKDF2 Parameters.
        ///
        /// - Parameters:
        ///   - salt: The salt for the derivation.
        ///   - keyLength: the length of the resulting key, must be at least 1.
        ///   - iterationCount: the number of iterations to use, must be between 1 and 10,000,000.
        ///   - prf: a PRF to use, the default is `hmacWithSha1` for specification reasons, but you should absolutely use something else.
        internal init?(
            salt: Data,
            iterationCount: UInt32,
            keyLength: UInt16?,
            prf: Pkcs5.Pbkdf2Prf = .hmacWithSha1
        ) {
            guard (1...Self.maxIterations).contains(iterationCount) else {
                return nil
            }

            if let keyLength = keyLength {
                guard (1...).contains(keyLength) else {
                    return nil
                }
            }

            self.salt = salt
            self.iterationCount = iterationCount
            self.keyLength = keyLength
            self.prf = prf
        }

        internal static let maxIterations: UInt32 = 10_000_000

        internal let salt: Data
        internal let iterationCount: UInt32
        internal let keyLength: UInt16?
        internal let prf: Pbkdf2Prf
    }

    /// ```text
    ///  PBKDF2-PRFs ALGORITHM-IDENTIFIER ::= {
    ///    {NULL IDENTIFIED BY id-hmacWithSHA1},
    ///    {NULL IDENTIFIED BY id-hmacWithSHA224},
    ///    {NULL IDENTIFIED BY id-hmacWithSHA256},
    ///    {NULL IDENTIFIED BY id-hmacWithSHA384},
    ///    {NULL IDENTIFIED BY id-hmacWithSHA512},
    ///    {NULL IDENTIFIED BY id-hmacWithSHA512-224},
    ///    {NULL IDENTIFIED BY id-hmacWithSHA512-256},
    ///    ...
    ///  }
    /// ```
    ///
    /// Currently supported algorithms: Whatever CommonCrypto supports
    internal enum Pbkdf2Prf {
        // supported because it's required
        case hmacWithSha1
        case hmacWithSha224
        case hmacWithSha256
        case hmacWithSha384
        case hmacWithSha512
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

    internal var ccPrf: CCPBKDFAlgorithm {
        switch self {
        case .hmacWithSha1: return CCPBKDFAlgorithm(kCCPRFHmacAlgSHA1)
        case .hmacWithSha224: return CCPBKDFAlgorithm(kCCPRFHmacAlgSHA224)
        case .hmacWithSha256: return CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256)
        case .hmacWithSha384: return CCPBKDFAlgorithm(kCCPRFHmacAlgSHA384)
        case .hmacWithSha512: return CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512)
        }
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

extension Pkcs5.Pbkdf2Prf: DERImplicitlyTaggable {
    internal static var defaultIdentifier: SwiftASN1.ASN1Identifier {
        .sequence
    }

    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        let algId = try Pkcs5.AlgorithmIdentifier(derEncoded: derEncoded, withIdentifier: identifier)

        // these specifically want `null` as in, not missing.
        guard let params = algId.parameters else {
            throw ASN1Error.invalidASN1Object(reason: "HMAC algorithm requires NULL parameters")
        }

        _ = try ASN1Null(asn1Any: params)

        switch algId.oid {
        case .DigestAlgorithm.hmacWithSha1: self = .hmacWithSha1
        case .DigestAlgorithm.hmacWithSha224: self = .hmacWithSha224
        case .DigestAlgorithm.hmacWithSha256: self = .hmacWithSha256
        case .DigestAlgorithm.hmacWithSha384: self = .hmacWithSha384
        case .DigestAlgorithm.hmacWithSha512: self = .hmacWithSha512
        default: throw ASN1Error.invalidASN1Object(reason: "unsupported algorithm identifier: \(algId.oid)")
        }
    }

    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try Pkcs5.AlgorithmIdentifier(oid: self.oid).serialize(into: &coder)
    }
}

extension Pkcs5.Pbkdf2Parameters: DERImplicitlyTaggable {
    internal static var defaultIdentifier: ASN1Identifier {
        .sequence
    }

    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(derEncoded, identifier: identifier) { nodes in
            // todo: otherSource
            let salt = try ASN1OctetString(derEncoded: &nodes)
            let iterationCount = try UInt32(derEncoded: &nodes)

            let keyLength: UInt16? = try DER.optionalImplicitlyTagged(&nodes)

            let prf = try DER.decodeDefault(&nodes, defaultValue: Pkcs5.Pbkdf2Prf.hmacWithSha1)

            guard
                let value = Self(salt: Data(salt.bytes), iterationCount: iterationCount, keyLength: keyLength, prf: prf)
            else {
                throw ASN1Error.invalidASN1Object(
                    reason:
                        "Invalid PBKDF2 parameters: iteration count must be between 1 and 10,000,000, and key length must be at least 1 if specified"
                )
            }

            return value
        }
    }

    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: .sequence) { coder in
            try coder.serialize(ASN1OctetString(contentBytes: Array(self.salt)[...]))
            try coder.serialize(iterationCount)

            if let keyLength = keyLength {
                try coder.serialize(keyLength)
            }

            if prf != .hmacWithSha1 {
                try coder.serialize(prf)
            }
        }
    }
}

extension Pkcs5.Pbkdf2Parameters {
    internal func derive(password: Data, keySize: Int) throws -> Data {
        if let keyLength = self.keyLength {
            guard Int(keyLength) == keySize else {
                throw HError.keyParse("invalid algorithm parameters")
            }
        }

        return Pkcs5.pbkdf2(
            prf: prf.ccPrf,
            password: password,
            salt: salt, rounds: self.iterationCount,
            keySize: keySize
        )
    }
}
