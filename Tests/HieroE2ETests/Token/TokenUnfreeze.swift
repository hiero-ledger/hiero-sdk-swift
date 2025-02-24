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

internal final class TokenUnfreeze: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let aliceFut = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)

        let (alice, bob) = try await (aliceFut, bobFut)

        let token = try await FungibleToken.create(testEnv, owner: alice)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenUnfreezeTransaction(accountId: bob.id, tokenId: token.id)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testMissingTokenIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        await assertThrowsHErrorAsync(
            try await TokenUnfreezeTransaction(accountId: account.id)
                .sign(account.key)
                .execute(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidTokenID)
        }
    }

    internal func testMissingAccountIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await TokenUnfreezeTransaction()
                .tokenId(token.id)
                .sign(account.key)
                .execute(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidAccountID)
        }
    }

    internal func testUnassociatedTokenFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let alice = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: alice)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let bob = try await bobFut

        await assertThrowsHErrorAsync(
            try await TokenUnfreezeTransaction(accountId: bob.id, tokenId: token.id)
                .sign(token.owner.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error freezing token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenNotAssociatedToAccount)
        }
    }
}
