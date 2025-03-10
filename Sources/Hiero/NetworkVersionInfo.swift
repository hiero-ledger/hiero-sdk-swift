// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Versions of Hedera Services, and the protobuf schema.
public struct NetworkVersionInfo {
    /// Version of the protobuf schema in use by the network.
    public let protobufVersion: SemanticVersion

    /// Version of the Hedera services in use by the network.
    public let servicesVersion: SemanticVersion

    /// Decode `Self` from protobuf-encoded `bytes`.
    ///
    /// - Throws: ``HError/ErrorKind/fromProtobuf`` if:
    ///           decoding the bytes fails to produce a valid protobuf, or
    ///            decoding the protobuf fails.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Convert `self` to protobuf encoded data.
    public func toBytes() -> Data {
        toProtobufBytes()
    }
}

extension NetworkVersionInfo: ProtobufCodable {
    internal typealias Protobuf = Proto_NetworkGetVersionInfoResponse

    internal init(protobuf proto: Protobuf) {
        self.protobufVersion = SemanticVersion.fromProtobuf(proto.hapiProtoVersion)
        self.servicesVersion = SemanticVersion.fromProtobuf(proto.hederaServicesVersion)
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.hapiProtoVersion = protobufVersion.toProtobuf()
            proto.hederaServicesVersion = servicesVersion.toProtobuf()
        }
    }
}
