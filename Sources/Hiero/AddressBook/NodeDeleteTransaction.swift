/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

/// A transaction body to delete a node from the network address book.
///
/// This transaction body SHALL be considered a "privileged transaction".
///
/// - A `NodeDeleteTransactionBody` MUST be signed by the governing council.
/// - Upon success, the address book entry SHALL enter a "pending delete"
///   state.
/// - All address book entries pending deletion SHALL be removed from the
///   active network configuration during the next `freeze` transaction with
///   the field `freeze_type` set to `PREPARE_UPGRADE`.<br/>
/// - A deleted address book node SHALL be removed entirely from network state.
/// - A deleted address book node identifier SHALL NOT be reused.
public final class NodeDeleteTransaction: Transaction {
    public init(
        nodeId: UInt64 = 0
    ) {
        self.nodeId = nodeId
        super.init()
    }

    internal init(
        protobuf proto: Proto_TransactionBody, _ data: Com_Hedera_Hapi_Node_Addressbook_NodeDeleteTransactionBody
    ) throws {
        self.nodeId = data.nodeID

        try super.init(protobuf: proto)
    }

    /// Node index to delete.
    public var nodeId: UInt64 {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the node index to delete.
    @discardableResult
    public func nodeId(_ nodeId: UInt64) -> Self {
        self.nodeId = nodeId

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {}

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_AddressBookServiceAsyncClient(channel: channel).deleteNode(request)
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .nodeDelete(toProtobuf())
    }
}

extension NodeDeleteTransaction: ToProtobuf {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Addressbook_NodeDeleteTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.nodeID = nodeId
        }
    }
}

extension NodeDeleteTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .nodeDelete(toProtobuf())
    }
}
