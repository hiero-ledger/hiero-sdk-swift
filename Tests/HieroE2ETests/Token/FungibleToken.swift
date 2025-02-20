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

import Hiero
import XCTest

let testAmount: Int64 = 100
let testMintedNfts: Int64 = 10
let testFungibleInitialBalance: UInt64 = 1_000_000

internal struct FungibleToken {
    internal let id: TokenId
    internal let owner: Account

    internal static func create(
        _ testEnv: NonfreeTestEnvironment,
        owner: Account? = nil,
        initialSupply: UInt64 = 0
    ) async throws -> Self {
        let privateKey = owner?.key ?? testEnv.operator.privateKey
        let owner = owner ?? Account(id: testEnv.operator.accountId, key: testEnv.operator.privateKey)

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("f")
            .tokenMemo("e2e test")
            .expirationTime(.now + .minutes(5))
            .decimals(3)
            .initialSupply(initialSupply)
            .treasuryAccountId(owner.id)
            .adminKey(.single(privateKey.publicKey))
            .freezeKey(.single(privateKey.publicKey))
            .wipeKey(.single(privateKey.publicKey))
            .supplyKey(.single(privateKey.publicKey))
            .metadataKey(.single(privateKey.publicKey))
            .pauseKey(.single(privateKey.publicKey))
            .kycKey(.single(privateKey.publicKey))
            .feeScheduleKey(.single(privateKey.publicKey))
            .freezeDefault(false)
            .freezeWith(testEnv.client)
            .sign(privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let id = try XCTUnwrap(receipt.tokenId)

        return Self(id: id, owner: owner)
    }

    internal static func create(
        _ testEnv: NonfreeTestEnvironment,
        decimals: UInt32
    ) async throws -> Self {
        let owner = Account(id: testEnv.operator.accountId, key: testEnv.operator.privateKey)

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("f")
            .tokenMemo("e2e test")
            .expirationTime(.now + .minutes(5))
            .decimals(decimals)
            .initialSupply(1_000_000)
            .maxSupply(1_000_000)
            .treasuryAccountId(testEnv.operator.accountId)
            .tokenSupplyType(.finite)
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .freezeKey(.single(testEnv.operator.privateKey.publicKey))
            .wipeKey(.single(testEnv.operator.privateKey.publicKey))
            .supplyKey(.single(testEnv.operator.privateKey.publicKey))
            .metadataKey(.single(testEnv.operator.privateKey.publicKey))
            .pauseKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let id = try XCTUnwrap(receipt.tokenId)

        return Self(id: id, owner: owner)
    }

    internal func burn(_ testEnv: NonfreeTestEnvironment, supply amount: UInt64) async throws {
        _ = try await TokenBurnTransaction(tokenId: id, amount: amount)
            .sign(owner.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func delete(_ testEnv: NonfreeTestEnvironment) async throws {
        _ = try await TokenDeleteTransaction(tokenId: id)
            .sign(owner.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }
}
