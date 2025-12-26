// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenNftTransferIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()
        let (tokenId, supplyKey) = try await createNftWithSupplyKey(
            treasuryAccountId: alice.accountId,
            treasuryKey: alice.key
        )

        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let serials = try XCTUnwrap(mintReceipt.serials)

        let transferTx = TransferTransaction()

        for serial in serials[..<4] {
            transferTx.nftTransfer(NftId(tokenId: tokenId, serial: serial), alice.accountId, bob.accountId)
        }

        // When / Then
        _ =
            try await transferTx
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func test_UnownedNftsFails() async throws {
        // Given
        let alice = try await createTestAccount()
        let bob = try await createTestAccount()
        let (tokenId, supplyKey) = try await createNftWithSupplyKey(
            treasuryAccountId: alice.accountId,
            treasuryKey: alice.key
        )

        try await associateToken(tokenId, with: bob.accountId, key: bob.key)

        let mintReceipt = try await TokenMintTransaction()
            .tokenId(tokenId)
            .metadata(TestConstants.testMetadata)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let serials = try XCTUnwrap(mintReceipt.serials)

        let transferTx = TransferTransaction()
        for serial in serials[..<4] {
            transferTx.nftTransfer(NftId(tokenId: tokenId, serial: serial), bob.accountId, alice.accountId)
        }

        // When / Then
        await assertReceiptStatus(
            try await transferTx
                .sign(bob.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .senderDoesNotOwnNftSerialNo
        )
    }
}
