// SPDX-License-Identifier: Apache-2.0

import SwiftASN1

extension Pkcs5 {
    /// RFC 5280 algorithm identifier.
    ///
    /// ```text
    ///    AlgorithmIdentifier  ::=  SEQUENCE  {
    ///    algorithm               OBJECT IDENTIFIER,
    ///    parameters              ANY DEFINED BY algorithm OPTIONAL  }
    /// ```
    internal struct AlgorithmIdentifier {
        internal init(oid: ASN1ObjectIdentifier, parameters: ASN1Any? = nil) {
            self.oid = oid
            self.parameters = parameters
        }

        internal let oid: ASN1ObjectIdentifier
        internal let parameters: ASN1Any?

        internal var parametersOID: ASN1ObjectIdentifier? {
            try? parameters.map(ASN1ObjectIdentifier.init(asn1Any:))
        }
    }
}

extension Pkcs5.AlgorithmIdentifier: SwiftASN1.DERImplicitlyTaggable {
    internal static var defaultIdentifier: ASN1Identifier {
        .sequence
    }

    internal init(derEncoded: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(derEncoded, identifier: identifier) { nodes in
            let oid = try ASN1ObjectIdentifier(derEncoded: &nodes)
            let parameters = nodes.next().map(ASN1Any.init(derEncoded:))

            return Self(oid: oid, parameters: parameters)
        }
    }

    internal func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(oid)

            if let parameters = parameters {
                try coder.serialize(parameters)
            }
        }
    }
}
