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

internal class TokenBurn: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account, initialSupply: 10)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        // the CUT.
        // Note: If this fails, deleting the token will succeed, but deleting the account will fail.
        let receipt = try await TokenBurnTransaction(tokenId: token.id, amount: 10)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(receipt.totalSupply, 0)
    }

    internal func testMissingTokenIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenBurnTransaction(amount: 10).execute(testEnv.client),
            "expected error burning token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidTokenID)
        }
    }

    internal func testBurnZero() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account, initialSupply: 0)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let receipt = try await TokenBurnTransaction(tokenId: token.id, amount: 0)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(receipt.totalSupply, 0)
    }

    internal func testMissingSupplyKeySigFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account, initialSupply: 0)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await TokenBurnTransaction(tokenId: token.id, amount: 0)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error burning token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testBurnNfts() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await Nft.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let serials = try await token.mint(testEnv, count: 10)

        // this is specifically what we're testing here.
        _ = try await TokenBurnTransaction(tokenId: token.id, serials: serials)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testUnownedNftFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let alice = makeAccount(testEnv)
        async let bob = makeAccount(testEnv)

        let token = try await Nft.create(testEnv, owner: alice)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let serials = try await token.mint(testEnv, count: 1)

        let nft = token.id.nft(serials[0])

        addTeardownBlock {
            try await token.burn(testEnv, serials: [nft.serial])
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .nftTransfer(nft, alice.id, bob.id)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        do {
            let alice = try await alice
            let bob = try await bob

            addTeardownBlock {
                _ = try await TransferTransaction()
                    .nftTransfer(nft, bob.id, alice.id)
                    .sign(bob.key)
                    .execute(testEnv.client)
                    .getReceipt(testEnv.client)
            }
        }

        let aliceKey = try await alice.key

        await assertThrowsHErrorAsync(
            try await TokenBurnTransaction(tokenId: token.id, serials: [nft.serial])
                .sign(aliceKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error burning token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .treasuryMustOwnBurnedNft)
        }
    }
}
