// SPDX-License-Identifier: Apache-2.0

extension Transaction {
    /// Create a ``FeeEstimateQuery`` for this transaction.
    ///
    /// Convenience shorthand for:
    /// ```swift
    /// FeeEstimateQuery(transaction: self)
    /// ```
    ///
    /// ## Example
    /// ```swift
    /// let estimate = try await myTransaction
    ///     .estimateFee()
    ///     .execute(client)
    /// ```
    public func estimateFee() -> FeeEstimateQuery {
        FeeEstimateQuery(transaction: self)
    }
}
