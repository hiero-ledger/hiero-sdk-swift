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
