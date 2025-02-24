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

    /// Whether the receipt/record status should be validated.
    public var validateStatus: Bool = true

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
        try await getReceiptQuery().execute(client, timeout)
    }

    /// Returns a query that when executed, returns the receipt for the associated transaction.
    public func getReceiptQuery() -> TransactionReceiptQuery {
        TransactionReceiptQuery()
            .transactionId(transactionId)
            .nodeAccountIds([nodeAccountId])
            .validateStatus(validateStatus)
    }

    /// Get the record for the associated transaction.
    ///
    /// Will wait for consensus.
    ///
    /// - Throws: an error of type ``HError``.
    public func getRecord(_ client: Client, _ timeout: TimeInterval? = nil) async throws -> TransactionRecord {
        try await getRecordQuery().execute(client, timeout)
    }

    /// Returns a query that when executed, returns the record for the associated transaction.
    public func getRecordQuery() -> TransactionRecordQuery {
        TransactionRecordQuery()
            .transactionId(transactionId)
            .nodeAccountIds([nodeAccountId])
            .validateStatus(validateStatus)
    }
}
