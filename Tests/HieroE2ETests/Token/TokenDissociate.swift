// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TokenDissociate: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let alice = makeAccount(testEnv)
        async let bob = makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: alice)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenDissociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testMissingTokenId() async throws {
        let testEnv = try TestEnvironment.nonFree

        _ = try await TokenDissociateTransaction(accountId: testEnv.operator.accountId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testMissingAccountIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenDissociateTransaction().execute(testEnv.client),
            "expected error dissociating from token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidAccountID)
        }
    }

    internal func testMissingSignatureFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        await assertThrowsHErrorAsync(
            try await TokenDissociateTransaction(accountId: account.id)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error dissociating from token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
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
            try await TokenDissociateTransaction(accountId: bob.id, tokenIds: [token.id])
                .sign(bob.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error dissociating from token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenNotAssociatedToAccount)
        }
    }
}
