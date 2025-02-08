// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// The total fees charged for a transaction, consisting of 3 parts:
/// The node fee, the network fee, and the service fee.
public struct FeeData {
    // missing_docs on memberwise init -> fine.
    // swiftlint:disable:next missing_docs
    public init(node: FeeComponents, network: FeeComponents, service: FeeComponents, kind: FeeDataType) {
        self.node = node
        self.network = network
        self.service = service
        self.kind = kind
    }

    /// Fee charged by the node for this functionality.
    public var node: FeeComponents

    /// Fee charged by Hedera for network operations.
    public var network: FeeComponents

    /// Fee charged by Hedera for providing the service.
    public var service: FeeComponents

    /// A subtype distinguishing between different types of fee data
    /// correlating to the same hedera functionality.
    public var kind: FeeDataType

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

extension FeeData: TryProtobufCodable {
    internal typealias Protobuf = Proto_FeeData

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            node: .fromProtobuf(proto.nodedata),
            network: .fromProtobuf(proto.networkdata),
            service: .fromProtobuf(proto.servicedata),
            kind: try .fromProtobuf(proto.subType)
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.nodedata = node.toProtobuf()
            proto.networkdata = network.toProtobuf()
            proto.servicedata = service.toProtobuf()
            proto.subType = kind.toProtobuf()
        }
    }
}
