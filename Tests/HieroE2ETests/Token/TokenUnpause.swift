// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TokenUnpause: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let owner = Account.create(testEnv)

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .treasuryAccountId(owner.id)
            .expirationTime(.now + .minutes(5))
            .decimals(3)
            .pauseKey(.single(owner.key.publicKey))
            .sign(owner.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        _ = try await TokenUnpauseTransaction().tokenId(tokenId).sign(owner.key).execute(testEnv.client).getReceipt(
            testEnv.client)
    }

    internal func testMissingTokenIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenUnpauseTransaction().execute(testEnv.client),
            "expected error Token Unpause"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidTokenID)
        }
    }

    internal func testMissingPauseKeySigFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let owner = Account.create(testEnv)

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .decimals(3)
            .treasuryAccountId(owner.id)
            .expirationTime(.now + .minutes(5))
            .pauseKey(.single(owner.key.publicKey))
            .sign(owner.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        await assertThrowsHErrorAsync(
            try await TokenUnpauseTransaction().tokenId(tokenId).execute(testEnv.client).getReceipt(testEnv.client),
            "expected error Token Unpause"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testMissingPauseKeyFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let owner = Account.create(testEnv)

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .treasuryAccountId(owner.id)
            .expirationTime(.now + .minutes(5))
            .sign(owner.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        await assertThrowsHErrorAsync(
            try await TokenUnpauseTransaction().tokenId(tokenId).execute(testEnv.client).getReceipt(testEnv.client),
            "expected error Token Unpause"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenHasNoPauseKey)
        }
    }
}
