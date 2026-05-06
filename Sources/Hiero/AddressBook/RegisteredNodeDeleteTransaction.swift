// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

/// A transaction body to delete a registered node from the network address book.
///
/// Must be signed by the registered node's `adminKey` or authorized by the
/// network governance structure.
public final class RegisteredNodeDeleteTransaction: Transaction {
    public init(
        registeredNodeId: UInt64 = 0
    ) {
        self.registeredNodeId = registeredNodeId
        super.init()
    }

    internal init(
        protobuf proto: Proto_TransactionBody,
        _ data: Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeDeleteTransactionBody
    ) throws {
        self.registeredNodeId = data.registeredNodeID

        try super.init(protobuf: proto)
    }

    /// The ID of the registered node to delete.
    public var registeredNodeId: UInt64 {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the registered node ID to delete.
    @discardableResult
    public func registeredNodeId(_ registeredNodeId: UInt64) -> Self {
        self.registeredNodeId = registeredNodeId

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {}

    internal override func transactionExecute(
        _ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval
    ) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_AddressBookServiceAsyncClient(channel: channel).deleteRegisteredNode(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .registeredNodeDelete(toProtobuf())
    }
}

extension RegisteredNodeDeleteTransaction: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeDeleteTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.registeredNodeID = registeredNodeId
        }
    }
}

extension RegisteredNodeDeleteTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .registeredNodeDelete(toProtobuf())
    }
}
