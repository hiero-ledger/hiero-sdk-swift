// SPDX-License-Identifier: Apache-2.0

internal struct Operator {
    internal let accountId: AccountId
    internal let signer: Signer

    internal func generateTransactionId() -> TransactionId {
        .generateFrom(accountId)
    }
}
