// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TokenFeeScheduleUpdateTransactionIntegrationTests: HieroIntegrationTestCase {
    internal func test_Basic() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey)),
            key: accountKey
        )

        let adminKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(accountId)
                .adminKey(.single(adminKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .sign(adminKey)
                .sign(accountKey),
            adminKey: adminKey
        )

        let customFees: [AnyCustomFee] = [
            .fixed(.init(amount: 10, feeCollectorAccountId: accountId)),
            .fractional(.init(amount: "1/20", minimumAmount: 1, maximumAmount: 10, feeCollectorAccountId: accountId)),
        ]

        // When
        _ = try await TokenFeeScheduleUpdateTransaction()
            .tokenId(tokenId)
            .customFees(customFees)
            .freezeWith(testEnv.client)
            .sign(feeScheduleKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await TokenInfoQuery().tokenId(tokenId).execute(testEnv.client)
        XCTAssertEqual(info.customFees, customFees)
    }

    internal func test_InvalidSignatureFails() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey)),
            key: accountKey
        )

        let adminKey = PrivateKey.generateEd25519()
        let feeScheduleKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(testEnv.operator.accountId)
                .adminKey(.single(adminKey.publicKey))
                .feeScheduleKey(.single(feeScheduleKey.publicKey))
                .sign(adminKey),
            adminKey: adminKey
        )

        let customFees: [AnyCustomFee] = [
            .fixed(.init(amount: 10, feeCollectorAccountId: accountId)),
            .fractional(.init(amount: "1/20", minimumAmount: 1, maximumAmount: 10, feeCollectorAccountId: accountId)),
        ]

        // When / Then
        await assertReceiptStatus(
            try await TokenFeeScheduleUpdateTransaction()
                .tokenId(tokenId)
                .customFees(customFees)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }
}
