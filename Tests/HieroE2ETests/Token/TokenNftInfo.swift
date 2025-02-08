// SPDX-License-Identifier: Apache-2.0

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
