// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

public final class BatchTransaction: Transaction {
    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_AtomicBatchTransactionBody) throws {
        self.transactions = try data.transactions.map { try Transaction.fromBytes($0) }

        try super.init(protobuf: proto)
    }

    public init(
        transactions: [Transaction] = []
    ) {
        self.transactions = transactions

        super.init()
    }

    /*
     * Set the list of transactions to be executed as part of this BatchTransaction.
     */
    public var transactions: [Transaction] {
        willSet {
            ensureNotFrozen()
        }
    }

    /*
     * Get the list of transactions this BatchTransaction is currently configured to execute.
     */
    @discardableResult
    public func innerTransactions(_ transactions: [Transaction]) -> Self {
        self.transactions = transactions

        return self
    }

    /*
     * Append a transaction to the list of transactions that will execute.
     */
    @discardableResult
    public func addInnerTransaction(_ transaction: Transaction) -> Self {
        self.transactions.append(transaction)

        return self
    }

    public var innerTransactionIds: [TransactionId] {
        return transactions.map { $0.transactionId! }
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction, _ deadline: TimeInterval) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_UtilServiceNIOClient(channel: channel).atomicBatch(request, callOptions: applyGrpcHeader(deadline: deadline))
            .response.get()
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .atomicBatch(toProtobuf())
    }
}

extension BatchTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_AtomicBatchTransactionBody

    internal func toProtobuf() -> Protobuf {
        return try! .with { proto in
            proto.transactions = try Transaction.toSerializedProtoTransactions(transactions)
        }
    }
}
