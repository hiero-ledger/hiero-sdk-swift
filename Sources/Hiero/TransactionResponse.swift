// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Response from ``Transaction/execute(_:_:).
///
/// When the client sends a node a transaction of any kind, the node replies with this, which
/// simply says that the transaction passed the pre-check (so the node will submit it to
/// the network).
///
/// To learn the consensus result, the client should later obtain a
/// receipt (free), or can buy a more detailed record (not free).
public struct TransactionResponse: Sendable {
    /// The account ID of the node that the transaction was submitted to.
    public let nodeAccountId: AccountId

    /// The client-generated transaction ID of the transaction that was submitted.
    ///
    /// This can be used to lookup the transaction in an explorer.
    public let transactionId: TransactionId

    /// The client-generated SHA-384 hash of the transaction that was submitted.
    ///
    /// This can be used to lookup the transaction in an explorer.
    public let transactionHash: TransactionHash

    /// Transaction-specific node account IDs, when explicitly configured on the transaction.
    internal let transactionNodeAccountIds: [AccountId]?

    /// Whether the receipt/record status should be validated.
    public var validateStatus: Bool = true

    internal init(
        nodeAccountId: AccountId,
        transactionId: TransactionId,
        transactionHash: TransactionHash,
        transactionNodeAccountIds: [AccountId]? = nil
    ) {
        self.nodeAccountId = nodeAccountId
        self.transactionId = transactionId
        self.transactionHash = transactionHash
        self.transactionNodeAccountIds = transactionNodeAccountIds
    }

    /// Whether the receipt/record status should be validated.
    @discardableResult
    public mutating func validateStatus(_ validateStatus: Bool) -> Self {
        self.validateStatus = validateStatus

        return self
    }

    /// Queries the receipt for the associated transaction.
    ///
    /// Will wait for consensus.
    ///
    /// - Throws: an error of type ``HError``.
    public func getReceipt(_ client: Client, _ timeout: TimeInterval? = nil) async throws -> TransactionReceipt {
        try await getReceiptQuery(client).execute(client, timeout)
    }

    /// Returns a query that when executed, returns the receipt for the associated transaction.
    public func getReceiptQuery(_ client: Client? = nil) -> TransactionReceiptQuery {
        TransactionReceiptQuery()
            .transactionId(transactionId)
            .nodeAccountIds(receiptNodeAccountIds(client))
            .validateStatus(validateStatus)
    }

    /// Get the record for the associated transaction.
    ///
    /// Will wait for consensus.
    ///
    /// - Throws: an error of type ``HError``.
    public func getRecord(_ client: Client, _ timeout: TimeInterval? = nil) async throws -> TransactionRecord {
        try await getRecordQuery(client).execute(client, timeout)
    }

    /// Returns a query that when executed, returns the record for the associated transaction.
    public func getRecordQuery(_ client: Client? = nil) -> TransactionRecordQuery {
        TransactionRecordQuery()
            .transactionId(transactionId)
            .nodeAccountIds(receiptNodeAccountIds(client))
            .validateStatus(validateStatus)
    }

    private func receiptNodeAccountIds(_ client: Client?) -> [AccountId] {
        guard client?.allowReceiptNodeFailover == true else {
            return [nodeAccountId]
        }

        let fallbackNodeAccountIds = transactionNodeAccountIds ?? client?.consensus.nodes ?? []
        return [nodeAccountId].appendingUnique(fallbackNodeAccountIds)
    }
}

extension Array where Element == AccountId {
    fileprivate func appendingUnique(_ accountIds: [AccountId]) -> [AccountId] {
        var seen = Set(self)
        var result = self
        result.reserveCapacity(self.count + accountIds.count)

        for accountId in accountIds where seen.insert(accountId).inserted {
            result.append(accountId)
        }

        return result
    }
}
