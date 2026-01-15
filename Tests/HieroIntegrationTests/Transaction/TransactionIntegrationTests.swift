// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TransactionIntegrationTests: HieroIntegrationTestCase {

    // MARK: - HIP-1300 Tests

    /// HIP-1300 defines ~6KB as the maximum size for a transaction for a normal account
    /// and ~130KB for an admin account. We use 8KB as the testable transaction size
    /// otherwise the test would take too long to run. This is a compromise between test
    /// speed and test coverage.
    private let testableTransactionSize = 8_000

    internal func test_CreateTransactionWithLargeSignaturesUsingAdminAccount() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let transaction = AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))

        while try transaction.toBytes().count < testableTransactionSize {
            _ = transaction.sign(PrivateKey.generateEd25519())
        }

        // When / Then
        _ = try await createAccount(transaction, key: accountKey, useAdminClient: true)
    }

    internal func test_CreateFileTransactionWithLargeDataUsingAdminAccount() async throws {
        // Given
        let fileAdminKey = PrivateKey.generateEd25519()
        let largeContents = Data(repeating: 1, count: 1024 * 10)

        // When / Then
        _ = try await createFile(
            FileCreateTransaction()
                .keys([.single(fileAdminKey.publicKey)])
                .contents(largeContents)
                .sign(fileAdminKey),
            key: fileAdminKey,
            useAdminClient: true)
    }

    internal func test_CreateFileTransactionWithLargeDataUsingRegularAccountFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await FileCreateTransaction()
                .contents(Data(repeating: 1, count: testableTransactionSize))
                .execute(testEnv.client),
            .transactionOversize
        )
    }

    internal func test_CreateTransactionWithLargeSignaturesUsingRegularAccountFails() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let transaction = AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))

        while try transaction.toBytes().count < testableTransactionSize {
            _ = transaction.sign(PrivateKey.generateEd25519())
        }

        // When / Then
        await assertPrecheckStatus(
            try await transaction.execute(testEnv.client),
            .transactionOversize
        )
    }

    // MARK: - HIP-1313 High-Volume Throttle Tests

    /// Test that creating an account with highVolume(true) succeeds.
    ///
    /// Note: This test verifies that the highVolume flag is correctly serialized and
    /// transmitted to the network. The actual high-volume throttle behavior depends
    /// on network configuration and may not be enabled on all networks.
    internal func test_CreateAccountWithHighVolume() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()

        // When
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .initialBalance(TestConstants.testSmallHbarBalance)
                .highVolume(true)
                .maxTransactionFee(Hbar(5)),
            key: accountKey
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        XCTAssertNotNil(info.accountId)
        XCTAssertEqual(info.key, .single(accountKey.publicKey))
    }

    /// Test that creating an account with highVolume(true) and maxTransactionFee works.
    ///
    /// This verifies that when using high-volume throttles, the maxTransactionFee
    /// setting is respected.
    internal func test_CreateAccountWithHighVolumeAndMaxFee() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let maxFee = Hbar(10)

        // When
        let accountId = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(accountKey.publicKey))
                .highVolume(true)
                .maxTransactionFee(maxFee),
            key: accountKey
        )

        // Then
        let info = try await AccountInfoQuery(accountId: accountId).execute(testEnv.client)
        XCTAssertNotNil(info.accountId)
    }

    /// Test that the highVolume flag is correctly preserved through serialization.
    internal func test_HighVolumeFlagSerializationRoundTrip() async throws {
        // Given
        let accountKey = PrivateKey.generateEd25519()
        let tx = try AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))
            .initialBalance(TestConstants.testSmallHbarBalance)
            .highVolume(true)
            .maxTransactionFee(Hbar(5))
            .nodeAccountIds([AccountId(3)])
            .transactionId(TransactionId.generate(testEnv.operator.accountId))
            .freeze()

        // When
        let bytes = try tx.toBytes()
        let deserializedTx = try Transaction.fromBytes(bytes)

        // Then
        XCTAssertTrue(deserializedTx.highVolume)
    }
}
