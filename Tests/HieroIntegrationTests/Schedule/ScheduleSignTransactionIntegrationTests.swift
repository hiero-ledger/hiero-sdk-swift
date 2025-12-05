// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class ScheduleSignTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_TransferSign() async throws {
        // Given
        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()
        let keyList: KeyList = [.single(key1.publicKey), .single(key2.publicKey)]

        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.keyList(keyList))
                .initialBalance(TestConstants.testSmallHbarBalance),
            keys: [key1, key2]
        )

        let scheduleId = try await createUnmanagedSchedule(
            standardScheduledTransfer(from: accountId).sign(key1)
        )

        // When
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .sign(key2)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)
        assertScheduleExecuted(info)
        XCTAssertEqual(info.signatories.count, 3)
    }

    internal func test_TransferSignWithMissingSigFail() async throws {
        // Given
        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()
        let keyList: KeyList = [.single(key1.publicKey), .single(key2.publicKey)]

        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.keyList(keyList))
                .initialBalance(TestConstants.testSmallHbarBalance),
            keys: [key1, key2]
        )

        let scheduleId = try await createSchedule(
            standardScheduledTransferWithAdminKey(from: accountId)
                .freezeWith(testEnv.client)
                .sign(key1),
            adminKey: testEnv.operator.privateKey
        )

        // When / Then
        await assertReceiptStatus(
            try await ScheduleSignTransaction()
                .scheduleId(scheduleId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .noNewValidSignatures
        )
    }

    internal func test_TokenMintSign() async throws {
        // Given
        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("ffff")
                .symbol("f")
                .initialSupply(0)
                .treasuryAccountId(testEnv.operator.accountId)
                .supplyKey(.single(supplyKey.publicKey)),
            supplyKey: supplyKey
        )

        let scheduleId = try await createUnmanagedSchedule(
            TokenMintTransaction()
                .tokenId(tokenId)
                .amount(TestConstants.testOperationAmount)
                .schedule()
        )

        // When
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)
        assertScheduleExecuted(info)
    }

    internal func test_SignWithMultiSigAndUpdateSigningRequirements() async throws {
        // Given
        let privateKey1 = PrivateKey.generateEd25519()
        let privateKey2 = PrivateKey.generateEd25519()
        let privateKey3 = PrivateKey.generateEd25519()
        let privateKey4 = PrivateKey.generateEd25519()
        let keyList = KeyList.init(
            keys: [
                .single(privateKey1.publicKey),
                .single(privateKey2.publicKey),
                .single(privateKey3.publicKey),
            ],
            threshold: 2)

        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.keyList(keyList))
                .initialBalance(TestConstants.testMediumHbarBalance),
            keys: [privateKey4]
        )

        let scheduleId = try await createUnmanagedSchedule(
            TransferTransaction()
                .hbarTransfer(testEnv.operator.accountId, Hbar(1))
                .hbarTransfer(accountId, -Hbar(1))
                .schedule()
                .expirationTime(.now + .seconds(86400))
                .scheduleMemo("HIP-423 e2e Test")
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .freezeWith(testEnv.client)
                .sign(privateKey1)
        )

        _ = try await AccountUpdateTransaction()
            .accountId(accountId)
            .key(.single(privateKey4.publicKey))
            .freezeWith(testEnv.client)
            .sign(privateKey1)
            .sign(privateKey2)
            .sign(privateKey4)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When
        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(testEnv.client)
            .sign(privateKey4)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        let info = try await ScheduleInfoQuery(scheduleId: scheduleId).execute(testEnv.client)
        assertScheduleExecuted(info)
    }
}
