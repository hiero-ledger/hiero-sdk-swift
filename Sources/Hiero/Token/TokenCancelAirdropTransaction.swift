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

import GRPC
import HieroProtobufs

/// Token cancel airdrop
/// Remove one or more pending airdrops from state on behalf of the sender(s)
/// for each airdrop.
///
/// Each pending airdrop canceled SHALL be removed from state and SHALL NOT be available to claim.
/// Each cancellation SHALL be represented in the transaction body and SHALL NOT be restated
/// in the record file.
/// All cancellations MUST succeed for this transaction to succeed.
public final class TokenCancelAirdropTransaction: Transaction {
    /// Create a new `TokenCancelAirdropTransaction`.
    public init(
        pendingAirdropIds: [PendingAirdropId] = []
    ) {
        self.pendingAirdropIds = pendingAirdropIds

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_TokenCancelAirdropTransactionBody) throws {
        self.pendingAirdropIds = try data.pendingAirdrops.map(PendingAirdropId.init)

        try super.init(protobuf: proto)
    }

    /// A list of one or more pending airdrop identifiers to cancel.
    public var pendingAirdropIds: [PendingAirdropId] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Adds the list of pending airdrop identifiers to cancel.
    @discardableResult
    public func pendingAirdropIds(_ pendingAirdropIds: [PendingAirdropId]) -> Self {
        self.pendingAirdropIds = pendingAirdropIds

        return self
    }

    /// Adds a pending airdrop identifier to the list of pending airdrop identifiers to cancel.
    @discardableResult
    public func addPendingAirdropId(_ pendingAirdropId: PendingAirdropId) -> Self {
        self.pendingAirdropIds.append(pendingAirdropId)

        return self
    }

    /// Clear the pending airdrop ids list
    @discardableResult
    public func clearPendingAirdropIds() -> Self {
        self.pendingAirdropIds = []

        return self
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_TokenServiceAsyncClient(channel: channel).cancelAirdrop(request)
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .tokenCancelAirdrop(toProtobuf())
    }
}

extension TokenCancelAirdropTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_TokenCancelAirdropTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.pendingAirdrops = pendingAirdropIds.map { $0.toProtobuf() }
        }
    }
}

extension TokenCancelAirdropTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .tokenCancelAirdrop(toProtobuf())
    }
}
