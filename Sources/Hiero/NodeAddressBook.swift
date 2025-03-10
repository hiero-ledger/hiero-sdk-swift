// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// A list of nodes and their metadata.
public struct NodeAddressBook {
    /// all the nodes this address book contains.
    public let nodeAddresses: [NodeAddress]

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

extension NodeAddressBook: TryProtobufCodable {
    internal typealias Protobuf = Proto_NodeAddressBook

    internal init(protobuf proto: Protobuf) throws {
        self.nodeAddresses = try .fromProtobuf(proto.nodeAddress)
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in proto.nodeAddress = nodeAddresses.toProtobuf() }
    }
}
