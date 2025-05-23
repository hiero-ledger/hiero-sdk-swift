// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TokenDelete: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account)

        _ = try await TokenDeleteTransaction(tokenId: token.id)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testOnlyAdminKey() async throws {
        let testEnv = try TestEnvironment.nonFree
        let account = try await makeAccount(testEnv)

        // n.b. `FungibleToken.create` sets all keys for convenience sake.
        let receipt = try await TokenCreateTransaction(
            name: "ffff",
            symbol: "F",
            treasuryAccountId: account.id,
            adminKey: .single(account.key.publicKey),
            expirationTime: .now + .minutes(5)
        )
        .sign(account.key)
        .execute(testEnv.client)
        .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        _ = try await TokenDeleteTransaction(tokenId: tokenId)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testMissingAdminKeySignatureFails() async throws {
        let testEnv = try TestEnvironment.nonFree
        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await TokenDeleteTransaction()
                .tokenId(token.id)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error deleting token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testMissingTokenIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenDeleteTransaction()
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error deleting token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidTokenID)
        }
    }
}
