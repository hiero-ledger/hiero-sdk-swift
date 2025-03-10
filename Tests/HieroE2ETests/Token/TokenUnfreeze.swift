// SPDX-License-Identifier: Apache-2.0

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
