// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Flow for verifying signatures via account info.
public enum AccountInfoFlow {}

extension AccountInfoFlow {
    private static func queryPublicKey(client: Client, accountId: AccountId) async throws -> PublicKey {
        let accountInfo = try await AccountInfoQuery(accountId: accountId).execute(client)

        switch accountInfo.key {
        case .single(let publicKey):
            return publicKey
        case let key:
            throw HError(
                kind: .signatureVerify,
                description: "Cannot verify signature for `\(accountId)`: unsupported key kind: \(key)"
            )
        }
    }

    /// Verify the `signature` for `message` via the given account's public key.
    public static func verifySignature(_ client: Client, _ accountId: AccountId, _ message: Data, _ signature: Data)
        async throws
    {
        let key = try await queryPublicKey(client: client, accountId: accountId)

        return try key.verify(message, signature)
    }

    /// Verify the given account's public key has signed the given transaction.
    public static func verifyTransactionSignature(_ client: Client, _ accountId: AccountId, _ transaction: Transaction)
        async throws
    {
        let key = try await queryPublicKey(client: client, accountId: accountId)

        return try key.verifyTransaction(transaction)
    }
}
