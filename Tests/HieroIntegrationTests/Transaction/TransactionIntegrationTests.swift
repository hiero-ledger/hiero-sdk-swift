// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TransactionIntegrationTests: HieroIntegrationTestCase {

    // MARK: - HIP-1300 Tests

    /// HIP-1300 defines ~6KB as the maximum size for a transaction for a normal account
    /// and ~130KB for an admin account. We use 8KB as the testable transaction size
    //  otherwise the test would take too long to run. This is a compromise between test
    // speed and test coverage.
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
}
