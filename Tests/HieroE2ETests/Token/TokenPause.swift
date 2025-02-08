// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TokenPause: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let owner = Account.create(testEnv)
        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .treasuryAccountId(owner.id)
            .expirationTime(.now + .minutes(5))
            .pauseKey(.single(owner.key.publicKey))
            .sign(owner.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        _ = try await TokenPauseTransaction().tokenId(tokenId).sign(owner.key).execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testMissingTokenIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenPauseTransaction().execute(testEnv.client),
            "expected error Token Pause"
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
            .treasuryAccountId(owner.id)
            .expirationTime(.now + .minutes(5))
            .pauseKey(.single(owner.key.publicKey))
            .sign(owner.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        await assertThrowsHErrorAsync(
            try await TokenPauseTransaction().tokenId(tokenId).execute(testEnv.client).getReceipt(testEnv.client),
            "expected error Token Pause"
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
            try await TokenPauseTransaction().tokenId(tokenId).execute(testEnv.client).getReceipt(testEnv.client),
            "expected error Token Pause"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenHasNoPauseKey)
        }
    }
}
