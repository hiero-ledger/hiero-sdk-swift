// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class AccountDelete: XCTestCase {
    internal func testCreateThenDelete() async throws {
        let testEnv = try TestEnvironment.nonFree

        let key = PrivateKey.generateEd25519()

        try await testEnv.ratelimits.accountCreate()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(1)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let accountId = try XCTUnwrap(receipt.accountId)

        _ = try await AccountDeleteTransaction()
            .transferAccountId(testEnv.operator.accountId)
            .accountId(accountId)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            try await AccountInfoQuery(accountId: accountId).execute(testEnv.client),
            "expected error querying account"
        ) { error in
            guard case .queryNoPaymentPreCheckStatus(let status) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryNoPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .accountDeleted)
        }
    }

    internal func testMissingAccountIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await AccountDeleteTransaction()
                .transferAccountId(testEnv.operator.accountId)
                .execute(testEnv.client),
            "expected error deleting account"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .accountIDDoesNotExist)
        }
    }

    internal func testMissingDeleteeSignatureFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await Account.create(testEnv)

        // note: this is still useful because the intent is that the next transaction fails.
        addTeardownBlock {
            try await account.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await AccountDeleteTransaction()
                .transferAccountId(testEnv.operator.accountId)
                .accountId(account.id)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error deleting account"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }
}
