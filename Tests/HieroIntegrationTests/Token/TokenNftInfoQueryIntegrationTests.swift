// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenNftInfoQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount()
        let (tokenId, supplyKey) = try await createNftWithSupplyKey(
            treasuryAccountId: accountId,
            treasuryKey: accountKey
        )

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata([Data([50])])
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let serials = try XCTUnwrap(mintReceipt.serials)
        let nftId = NftId(tokenId: tokenId, serial: serials.first!)

        // When
        let nftInfo = try await TokenNftInfoQuery(nftId: nftId).execute(testEnv.client)

        // Then
        XCTAssertEqual(nftInfo.nftId, nftId)
        XCTAssertEqual(nftInfo.accountId, accountId)
        XCTAssertEqual(nftInfo.metadata, Data([50]))
    }

    internal func test_InvalidNftIdFails() async throws {
        // Given / When / Then
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

    internal func test_InvalidSerialNumberFails() async throws {
        // Given / When / Then
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
