// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class AccountUpdate: XCTestCase {
    internal func testSetKey() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()

        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key1.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(receipt.accountId)

        addTeardownBlock {
            // need a teardown block that signs with both keys because we don't know when this block is executed.
            // it could be executed right now, or after the update succeeds.
            _ = try await AccountDeleteTransaction()
                .accountId(accountId)
                .transferAccountId(testEnv.operator.accountId)
                .sign(key1)
                .sign(key2)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        do {
            let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

            XCTAssertEqual(info.key, .single(key1.publicKey))

            _ = try await AccountUpdateTransaction()
                .accountId(accountId)
                .key(.single(key2.publicKey))
                .sign(key1)
                .sign(key2)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)

        XCTAssertEqual(info.accountId, accountId)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.key, .single(key2.publicKey))
        XCTAssertEqual(info.balance, 0)
        XCTAssertEqual(info.autoRenewPeriod, .days(90))
        // fixme: ensure no warning gets emitted.
        // XCTAssertNil(info.proxyAccountId)
        XCTAssertEqual(info.proxyReceived, 0)

    }

    internal func testMissingAccountIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await AccountUpdateTransaction().execute(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .accountIDDoesNotExist)
        }
    }

    internal func testCannotUpdateTokenMaxAssociationToLowerValueFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let accountKey = PrivateKey.generateEd25519()

        // Create account with max token associations of 1
        let accountCreateReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))
            .maxAutomaticTokenAssociations(1)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(accountCreateReceipt.accountId)

        // Create token
        let tokenCreateReceipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .initialSupply(100_000)
            .treasuryAccountId(testEnv.operator.accountId)
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(tokenCreateReceipt.tokenId)

        // Associate token with account
        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, testEnv.operator.accountId, -10)
            .tokenTransfer(tokenId, accountId, 10)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            // Update account max token associations to 0
            try await AccountUpdateTransaction()
                .accountId(accountId)
                .maxAutomaticTokenAssociations(0)
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .existingAutomaticAssociationsExceedGivenLimit)
        }
    }
}
