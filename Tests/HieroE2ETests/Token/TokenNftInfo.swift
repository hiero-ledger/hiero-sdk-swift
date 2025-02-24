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

internal final class TokenNftInfo: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)
        let token = try await Nft.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let serials = try await token.mint(testEnv, metadata: [Data([50])])

        addTeardownBlock {
            try await token.burn(testEnv, serials: serials)
        }

        let nftId = token.id.nft(serials.first!)

        let nftInfo = try await TokenNftInfoQuery(nftId: nftId).execute(testEnv.client)

        XCTAssertEqual(nftInfo.nftId, nftId)
        XCTAssertEqual(nftInfo.accountId, account.id)
        XCTAssertEqual(nftInfo.metadata, Data([50]))
    }

    internal func testInvalidNftIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenNftInfoQuery(nftId: NftId(tokenId: 0, serial: 2023))
                .execute(testEnv.client)
        ) { error in
            guard case .queryNoPaymentPreCheckStatus(let status) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryNoPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidNftID)
        }
    }

    internal func testInvalidSerialNumberFails() async throws {
        let testEnv = try TestEnvironment.nonFree
        await assertThrowsHErrorAsync(
            try await TokenNftInfoQuery(nftId: NftId(tokenId: 0, serial: .max))
                .execute(testEnv.client)
        ) { error in
            guard case .queryNoPaymentPreCheckStatus(let status) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryNoPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidTokenNftSerialNumber)
        }
    }
}
