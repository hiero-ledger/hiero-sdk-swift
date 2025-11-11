// SPDX-License-Identifier: Apache-2.0

/// Operator account and signer for transaction authentication.
///
/// The operator is used to automatically sign transactions and generate transaction IDs.
internal struct Operator: Sendable {
    internal let accountId: AccountId
    internal let signer: Signer

    internal func generateTransactionId() -> TransactionId {
        .generateFrom(accountId)
    }
}
