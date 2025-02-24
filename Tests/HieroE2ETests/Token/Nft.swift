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

let testMetadata = Array(repeating: Data([9, 1, 6]), count: 10)

internal struct Nft {
    internal let id: TokenId
    internal let owner: Account

    internal static func create(_ testEnv: NonfreeTestEnvironment, owner: Account? = nil) async throws -> Self {
        let owner = owner ?? Account(id: testEnv.operator.accountId, key: testEnv.operator.privateKey)

        let receipt = try await TokenCreateTransaction(
            name: "ffff",
            symbol: "f",
            treasuryAccountId: owner.id,
            adminKey: Key.single(owner.key.publicKey),
            freezeKey: Key.single(owner.key.publicKey),
            wipeKey: Key.single(owner.key.publicKey),
            supplyKey: Key.single(owner.key.publicKey),
            freezeDefault: false,
            expirationTime: .now + .minutes(5),
            tokenType: .nonFungibleUnique,
            feeScheduleKey: Key.single(owner.key.publicKey),
            pauseKey: Key.single(owner.key.publicKey),
            metadataKey: Key.single(owner.key.publicKey)
        )
        .sign(owner.key)
        .execute(testEnv.client)
        .getReceipt(testEnv.client)

        let id = try XCTUnwrap(receipt.tokenId)

        return Self(id: id, owner: owner)
    }

    internal func mint(_ testEnv: NonfreeTestEnvironment, count nfts: UInt8) async throws -> [UInt64] {
        try await mint(testEnv, metadata: (0..<nfts).map { Data([$0]) })
    }

    internal func mint(_ testEnv: NonfreeTestEnvironment, metadata: [Data]) async throws -> [UInt64] {
        let receipt = try await TokenMintTransaction(tokenId: id, metadata: metadata)
            .sign(owner.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        return try XCTUnwrap(receipt.serials)
    }

    internal func burn(_ testEnv: NonfreeTestEnvironment, serials: [UInt64]) async throws {
        _ = try await TokenBurnTransaction(tokenId: id, serials: serials)
            .sign(owner.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func wipe(_ testEnv: NonfreeTestEnvironment, serials: [UInt64], from account: AccountId) async throws {
        _ = try await TokenWipeTransaction(tokenId: id, serials: serials)
            .accountId(account)
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
