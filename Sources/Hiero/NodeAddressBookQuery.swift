// SPDX-License-Identifier: Apache-2.0

import AnyAsyncSequence
import Foundation
import GRPC
import HieroProtobufs

public final class NodeAddressBookQuery: ValidateChecksums, MirrorQuery {
    public typealias Item = NodeAddress
    public typealias Response = NodeAddressBook

    private var fileId: FileId
    private var limit: UInt32

    public init(_ fileId: FileId = FileId.addressBook, _ limit: UInt32 = 0) {
        self.fileId = fileId
        self.limit = limit
    }

    public func getFileId() -> FileId {
        fileId
    }

    public func setFileId(_ fileId: FileId) -> Self {
        self.fileId = fileId
        return self
    }

    public func getLimit() -> UInt32 {
        limit
    }

    public func setLimit(_ limit: UInt32) -> Self {
        self.limit = limit
        return self
    }

    public func subscribe(_ client: Client, _ timeout: TimeInterval? = nil) -> AnyAsyncSequence<NodeAddress> {
        subscribeInner(client, timeout)
    }

    public func execute(_ client: Client, _ timeout: TimeInterval? = nil) async throws -> NodeAddressBook {
        try await executeInner(client, timeout)
    }

    internal func executeMirrornet(_ mirrorNet: MirrorNetwork) async throws -> NodeAddressBook {
        try await executeChannel(mirrorNet.channel)
    }

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try fileId.validateChecksums(on: ledgerId)
    }
}

extension NodeAddressBookQuery: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Mirror_Api_Proto_AddressBookQuery

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.fileID = fileId.toProtobuf()
            proto.limit = Int32(limit)
        }
    }
}

extension NodeAddressBookQuery: MirrorRequest {
    internal typealias GrpcItem = NodeAddress.Protobuf

    internal struct Context: MirrorRequestContext {
        internal mutating func update(item: GrpcItem) {
            // do nothing
        }
    }

    internal func connect(context: Context, channel: GRPCChannel) -> GRPCAsyncResponseStream<GrpcItem> {
        let request = self.toProtobuf()

        return HieroProtobufs.Com_Hedera_Mirror_Api_Proto_NetworkServiceAsyncClient(channel: channel).getNodes(request)
    }

    internal static func collect<S>(_ stream: S) async throws -> Response
    where S: AsyncSequence, GrpcItem == S.Element {
        var items: [Item] = []
        for try await proto in stream {
            items.append(try Item.fromProtobuf(proto))
        }

        return Response(nodeAddresses: items)
    }

    internal static func makeItemStream<S>(_ stream: S) -> ItemStream
    where S: AsyncSequence, NodeAddress.Protobuf == S.Element {
        stream.map(Item.fromProtobuf).eraseToAnyAsyncSequence()
    }
}
