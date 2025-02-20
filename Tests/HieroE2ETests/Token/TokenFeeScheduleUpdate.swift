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

internal final class TokenFeeScheduleUpdate: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        do {
            let info = try await TokenInfoQuery(tokenId: token.id).execute(testEnv.client)
            XCTAssert(info.customFees.isEmpty)
        }

        let customFees: [AnyCustomFee] = [
            .fixed(.init(amount: 10, feeCollectorAccountId: account.id)),
            .fractional(.init(amount: "1/20", minimumAmount: 1, maximumAmount: 10, feeCollectorAccountId: account.id)),
        ]

        _ = try await TokenFeeScheduleUpdateTransaction(tokenId: token.id, customFees: customFees)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await TokenInfoQuery(tokenId: token.id).execute(testEnv.client)

        XCTAssertEqual(customFees, info.customFees)
    }

    internal func testInvalidSignatureFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        do {
            let info = try await TokenInfoQuery(tokenId: token.id).execute(testEnv.client)
            XCTAssert(info.customFees.isEmpty)
        }

        let customFees: [AnyCustomFee] = [
            .fixed(.init(amount: 10, feeCollectorAccountId: account.id)),
            .fractional(.init(amount: "1/20", minimumAmount: 1, maximumAmount: 10, feeCollectorAccountId: account.id)),
        ]

        await assertThrowsHErrorAsync(
            try await TokenFeeScheduleUpdateTransaction(tokenId: token.id, customFees: customFees)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error updating token fee schedule"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }
}
