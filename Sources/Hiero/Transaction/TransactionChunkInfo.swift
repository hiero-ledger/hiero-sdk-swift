// SPDX-License-Identifier: Apache-2.0

internal struct ChunkInfo {
    internal let current: Int
    internal let total: Int
    internal let initialTransactionId: TransactionId
    internal let currentTransactionId: TransactionId
    internal let nodeAccountId: AccountId

    internal static func single(transactionId: TransactionId, nodeAccountId: AccountId) -> Self {
        .initial(total: 1, transactionId: transactionId, nodeAccountId: nodeAccountId)
    }

    internal static func initial(total: Int, transactionId: TransactionId, nodeAccountId: AccountId) -> Self {
        self.init(
            current: 0,
            total: total,
            initialTransactionId: transactionId,
            currentTransactionId: transactionId,
            nodeAccountId: nodeAccountId
        )
    }

    internal func assertSingleTransaction() -> (transactionId: TransactionId, nodeAccountId: AccountId) {
        precondition(self.current == 0 && self.total == 1)

        return (transactionId: self.currentTransactionId, nodeAccountId: self.nodeAccountId)
    }
}
