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
import SwiftProtobuf

/// Transfers cryptocurrency among two or more accounts by making the desired adjustments to their
/// balances.
///
/// Each transfer list can specify up to 10 adjustments. Each negative amount is withdrawn
/// from the corresponding account (a sender), and each positive one is added to the corresponding
/// account (a receiver). The amounts list must sum to zero.
///
///
/// All transfers are in the lowest denomination, for `Hbar` that is tinybars (although `Hbar` handles this itself).
///
/// As an example:
/// For a fungible token with `3` decimals (and let's say the symbol is `ƒ`), transferring `1` _always_ transfers `0.001 ƒ`.
public final class TransferTransaction: AbstractTokenTransferTransaction {
    /// Create a new `TransferTransaction`.
    public override init() {
        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_CryptoTransferTransactionBody) throws {
        try super.init(protobuf: proto)

        // init fields
        transfers = try .fromProtobuf(data.transfers.accountAmounts)
        tokenTransfersInner = try .fromProtobuf(data.tokenTransfers)
    }

    public var hbarTransfers: [AccountId: Hbar] {
        Dictionary(
            transfers.lazy.map { ($0.accountId, .fromTinybars($0.amount)) },
            uniquingKeysWith: { (first, second) in first })
    }

    /// Add a non-approved hbar transfer to the transaction.
    @discardableResult
    public func hbarTransfer(_ accountId: AccountId, _ amount: Hbar) -> Self {
        doHbarTransfer(accountId, amount.toTinybars(), false)
    }

    /// Add an approved hbar transfer to the transaction.
    @discardableResult
    public func approvedHbarTransfer(_ accountId: AccountId, _ amount: Hbar) -> Self {
        doHbarTransfer(accountId, amount.toTinybars(), true)
    }

    private func doHbarTransfer(
        _ accountId: AccountId,
        _ amount: Int64,
        _ approved: Bool
    ) -> Self {
        transfers.append(Transfer(accountId: accountId, amount: amount, isApproval: approved))

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try transfers.validateChecksums(on: ledgerId)
        try tokenTransfersInner.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_CryptoServiceAsyncClient(channel: channel).cryptoTransfer(request)
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .cryptoTransfer(toProtobuf())
    }
}

extension TransferTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .cryptoTransfer(toProtobuf())
    }
}

extension TransferTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_CryptoTransferTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.transfers = .with { $0.accountAmounts = transfers.toProtobuf() }
            proto.tokenTransfers = tokenTransfersInner.toProtobuf()
        }
    }
}
