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
