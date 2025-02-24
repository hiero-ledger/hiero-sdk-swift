import Foundation
import SwiftASN1

internal enum Sec1 {
    /// INTEGER { ecPrivkeyVer1(1) } (ecPrivkeyVer1)
    fileprivate enum Version: Int, Equatable {
        case v1 = 1
    }

    internal enum EcParameters {
        case namedCurve(ASN1ObjectIdentifier)

        var namedCurve: ASN1ObjectIdentifier? {
            if case .namedCurve(let oid) = self {
                return oid
            }

            return nil
        }
    }

    internal struct ECPrivateKey {
        /// ```text
        /// version        INTEGER { ecPrivkeyVer1(1) } (ecPrivkeyVer1),
        /// privateKey     OCTET STRING,
        /// parameters [0] ECParameters {{ NamedCurve }} OPTIONAL,
        /// publicKey  [1] BIT STRING OPTIONAL
        /// ```
        internal init(
            privateKey: ASN1OctetString,
            parameters: EcParameters?,
            publicKey: ASN1BitString? = nil
        ) {
            self.privateKey = privateKey
            self.parameters = parameters
            self.publicKey = publicKey
        }

        internal let privateKey: ASN1OctetString
        internal let parameters: EcParameters?
        internal let publicKey: ASN1BitString?

        fileprivate var version: Version { .v1 }
    }
}

extension Sec1.Version: DERImplicitlyTaggable {
    fileprivate static var defaultIdentifier: ASN1Identifier {
        .integer
    }

    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        let raw = try Int(derEncoded: derEncoded, withIdentifier: identifier)

        guard let value = Self(rawValue: raw) else {
            throw ASN1Error.invalidASN1Object
            // throw ASN1Error.invalidASN1Object(reason: "invalid Pkcs8.Version")
        }

        self = value
    }

    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier)
        throws
    {
        try coder.serialize(self.rawValue)
    }
}

extension Sec1.EcParameters: DERSerializable, DERParseable {
    internal init(derEncoded: ASN1Node) throws {
        // we're always going to be a namedCurve here because nothing else is allowed.
        self = try .namedCurve(ASN1ObjectIdentifier(derEncoded: derEncoded))
    }

    internal func serialize(into coder: inout DER.Serializer) throws {
        switch self {
        case .namedCurve(let oid):
            try oid.serialize(into: &coder)
        }
    }
}

extension Sec1.ECPrivateKey: DERImplicitlyTaggable {
    internal static let parametersTagNumber: UInt = 0
    internal static let publicKeyTagNumber: UInt = 1
    internal static var defaultIdentifier: ASN1Identifier {
        .sequence
    }

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
