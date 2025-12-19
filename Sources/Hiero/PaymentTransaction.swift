// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

internal final class PaymentTransaction: Transaction {
    internal var amount: Hbar?
    internal var maxAmount: Hbar?

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        let (transactionId, nodeAccountId) = chunkInfo.assertSingleTransaction()

        let amount = self.amount ?? 0

        return .cryptoTransfer(
            .with { proto in
                proto.transfers = .with { proto in
                    proto.accountAmounts = [
                        .with { proto in
                            proto.accountID = nodeAccountId.toProtobuf()
                            proto.amount = amount.toTinybars()
                            proto.isApproval = false
                        },
                        .with { proto in
                            proto.accountID = transactionId.accountId.toProtobuf()
                            proto.amount = -(amount.toTinybars())
                            proto.isApproval = false
                        },
                    ]
                }
            }
        )
    }

    internal override func transactionExecute(
        _ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval
    ) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_CryptoServiceAsyncClient(channel: channel).cryptoTransfer(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try super.validateChecksums(on: ledgerId)
    }
}
