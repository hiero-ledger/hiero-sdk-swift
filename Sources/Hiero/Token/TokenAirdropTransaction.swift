// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs
import SwiftProtobuf

public final class TokenAirdropTransaction: AbstractTokenTransferTransaction {
    /// Create a new `TokenAirdropTransaction`.
    public override init() {
        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_TokenAirdropTransactionBody) throws {
        try super.init(protobuf: proto)

        tokenTransfersInner = try .fromProtobuf(data.tokenTransfers)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try tokenTransfersInner.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_TokenServiceAsyncClient(channel: channel).airdropTokens(request)
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .tokenAirdrop(toProtobuf())
    }
}

extension TokenAirdropTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_TokenAirdropTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            let sortedTransfers = sortTransfers()

            proto.tokenTransfers = sortedTransfers.toProtobuf()
        }
    }
}
