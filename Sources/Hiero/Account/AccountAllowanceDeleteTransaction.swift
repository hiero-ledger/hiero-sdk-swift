// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Deletes one or more non-fungible approved allowances from an owner's account. This operation
/// will remove the allowances granted to one or more specific non-fungible token serial numbers. Each owner account
/// listed as wiping an allowance must sign the transaction. Hbar and fungible token allowances
/// can be removed by setting the amount to zero in `AccountAllowanceApproveTransaction`.
///
public final class AccountAllowanceDeleteTransaction: Transaction {
    public private(set) var nftAllowances: [NftRemoveAllowance] = [] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Create a new `AccountAllowanceDeleteTransaction`.
    public override init() {
        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_CryptoDeleteAllowanceTransactionBody) throws {
        nftAllowances = try .fromProtobuf(data.nftAllowances)

        try super.init(protobuf: proto)
    }

    /// Remove all nft token allowances.
    @discardableResult
    public func deleteAllTokenNftAllowances(_ nftId: NftId, _ ownerAccountId: AccountId) -> Self {
        ensureNotFrozen()

        let index = nftAllowances.firstIndex { allowance in
            allowance.tokenId == nftId.tokenId && allowance.ownerAccountId == ownerAccountId
        }

        if let index = index {
            nftAllowances[index].serials.append(nftId.serial)
        } else {
            nftAllowances.append(
                NftRemoveAllowance(
                    tokenId: nftId.tokenId,
                    ownerAccountId: ownerAccountId,
                    serials: [nftId.serial]
                )
            )
        }

        return self
    }

    public override func validateChecksums(on ledgerId: LedgerId) throws {
        try nftAllowances.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_CryptoServiceAsyncClient(channel: channel).deleteAllowances(request)
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .cryptoDeleteAllowance(toProtobuf())
    }
}

extension AccountAllowanceDeleteTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_CryptoDeleteAllowanceTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.nftAllowances = nftAllowances.toProtobuf()
        }
    }
}

extension AccountAllowanceDeleteTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .cryptoDeleteAllowance(toProtobuf())
    }
}
