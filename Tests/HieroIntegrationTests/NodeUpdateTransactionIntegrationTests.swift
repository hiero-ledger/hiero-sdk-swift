// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class NodeUpdateTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_NodeUpdateTransactionCanExecute() async throws {
        // Given / When
        let receipt = try await NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .declineRewards(true)
            .grpcWebProxyEndpoint(Endpoint(port: 123456, domainName: "testWebUpdated.com"))
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.nodeId, 0)
    }

    internal func test_NodeUpdateTransactionCanChangeNodeAccountIdToTheSameAccount() async throws {
        // Given / When
        let receipt = try await NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .accountId(AccountId(num: 3))
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)
    }

    internal func test_NodeUpdateTransactionCanChangeNodeAccountId() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)

        // When
        let receipt = try await NodeUpdateTransaction()
            .nodeId(1)
            .accountId(accountId)
            .freezeWith(testEnv.adminClient)
            .sign(accountKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Then
        XCTAssertEqual(receipt.status, .success)

        // Reset the node account ID to the original account ID
        _ = try await NodeUpdateTransaction()
            .nodeAccountIds([AccountId(num: 3)])
            .nodeId(1)
            .accountId(AccountId(num: 4))
            .freezeWith(testEnv.adminClient)
            .sign(accountKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        // Wait for mirror node to synchronize
        try await Task.sleep(nanoseconds: 5_000_000_000)
    }

    internal func test_NodeUpdateTransactionCanChangeNodeAccountIdInvalidSignature() async throws {
        // Given
        let (newOperatorAccountId, newOperatorKey) = try await createTestAccount(
            initialBalance: TestConstants.testMediumHbarBalance)

        let client = testEnv.client
        client.setOperator(newOperatorAccountId, newOperatorKey)

        // Attempt to update node account ID without proper signatures
        await assertReceiptStatus(
            try await NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(AccountId(num: 3))
                .execute(client)
                .getReceipt(client),
            .invalidSignature
        )
    }

    internal func test_NodeUpdateTransactionCanChangeNodeAccountIdToNonExistentAccountId() async throws {
        // Given / When / Then
        await assertReceiptStatus(
            try await NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(AccountId(num: 9_999_999))
                .freezeWith(testEnv.adminClient)
                .execute(testEnv.adminClient)
                .getReceipt(testEnv.adminClient),
            .invalidSignature
        )
    }

    internal func test_NodeUpdateTransactionCanChangeNodeAccountIdToDeletedAccountId() async throws {
        // Given
        let (accountId, accountKey) = try await createSimpleUnmanagedAccount()
        _ = try await AccountDeleteTransaction()
            .accountId(accountId)
            .transferAccountId(testEnv.operator.accountId)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // When / Then
        await assertReceiptStatus(
            try await NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(accountId)
                .freezeWith(testEnv.adminClient)
                .sign(accountKey)
                .execute(testEnv.adminClient)
                .getReceipt(testEnv.adminClient),
            .accountDeleted
        )
    }

    internal func test_NodeUpdateTransactionCanChangeNodeAccountIdMissingAdminKeySignature() async throws {
        // Given
        let (newAccountId, newAccountKey) = try await createTestAccount()
        let (nonAdminOperatorId, nonAdminOperatorKey) = try await createTestAccount(
            initialBalance: TestConstants.testMediumHbarBalance)

        let client = testEnv.client
        client.setOperator(nonAdminOperatorId, nonAdminOperatorKey)

        // When / Then
        await assertReceiptStatus(
            try await NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(newAccountId)
                .freezeWith(client)
                .sign(newAccountKey)  // Only sign with account key, not node admin key
                .execute(client)
                .getReceipt(client),
            .invalidSignature
        )
    }

    internal func test_NodeUpdateTransactionCannotRemoveAccountIdWithoutAdminKey() async throws {
        // Given
        let (newAccountId, _) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)
        let (newOperatorAccountId, newOperatorKey) = try await createTestAccount(
            initialBalance: TestConstants.testMediumHbarBalance)

        let client = testEnv.client
        client.setOperator(newOperatorAccountId, newOperatorKey)

        // When / Then
        await assertReceiptStatus(
            try await NodeUpdateTransaction()
                .nodeId(0)
                .accountId(newAccountId)
                .execute(client)
                .getReceipt(client),
            .invalidSignature
        )
    }

    internal func test_NodeUpdateTransactionCanChangeNodeAccountUpdateAddressbookAndRetry() async throws {
        // Given
        let (newAccountId, newAccountKey) = try await createTestAccount(initialBalance: Hbar(1))

        // When
        let updateReceipt = try await NodeUpdateTransaction()
            .nodeId(1)
            .accountId(newAccountId)
            .freezeWith(testEnv.adminClient)
            .sign(newAccountKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)
        XCTAssertEqual(updateReceipt.status, .success, "Node update transaction failed")

        try await Task.sleep(nanoseconds: 5_000_000_000)

        // Then
        let testKey = PrivateKey.generateEd25519()
        await assertPrecheckStatus(
            try await AccountCreateTransaction()
                .keyWithoutAlias(.single(testKey.publicKey))
                .nodeAccountIds([AccountId(num: 4)])
                .execute(testEnv.adminClient)
                .getReceipt(testEnv.adminClient),
            .invalidNodeAccount
        )

        _ = try await createAccount(
            AccountCreateTransaction()
                .keyWithoutAlias(.single(testKey.publicKey))
                .nodeAccountIds([newAccountId]),
            key: testKey
        )

        _ = try await NodeUpdateTransaction()
            .nodeId(1)
            .accountId(AccountId(num: 4))
            .freezeWith(testEnv.adminClient)
            .sign(newAccountKey)
            .execute(testEnv.adminClient)
            .getReceipt(testEnv.adminClient)

        try await Task.sleep(nanoseconds: 5_000_000_000)
    }
}
