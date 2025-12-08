// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class NodeUpdateTransactionIntegrationTests: HieroIntegrationTestCase {

    internal func test_DAB_NodeUpdateTransactionCanExecute() async throws {
        // Given / When
        let receipt = try await NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .declineRewards(true)
            .grpcWebProxyEndpoint(Endpoint(port: 123456, domainName: "testWebUpdated.com"))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.nodeId, 0)
    }

    internal func test_DAB_NodeUpdateTransactionCanChangeNodeAccountIdToTheSameAccount() async throws {
        // Given / When
        let receipt = try await NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .accountId(AccountId(num: 3))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)
    }

    internal func test_DAB_NodeUpdateTransactionCanChangeNodeAccountId() async throws {
        // Given
        let (accountId, accountKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)

        // When
        let receipt = try await NodeUpdateTransaction()
            .nodeAccountIds([AccountId(num: 3)])
            .nodeId(0)
            .accountId(accountId)
            .freezeWith(testEnv.client)
            .sign(accountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(receipt.status, .success)

        if receipt.status == .success {
            // Reset the node account ID to the original account ID
            _ = try await NodeUpdateTransaction()
                .nodeAccountIds([AccountId(num: 4)])
                .nodeId(0)
                .accountId(AccountId(num: 3))
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)

            XCTAssertEqual(receipt.status, .success, "Node update transaction failed to reset node account ID")
        }
    }

    internal func test_DAB_NodeUpdateTransactionCanChangeNodeAccountIdInvalidSignature() async throws {
        // Given
        let (newOperatorAccountId, newOperatorKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)

        // Change the operator to the new account
        _ = testEnv.client.setOperator(newOperatorAccountId, newOperatorKey)

        addTeardownBlock { [self] in
            _ = testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)
        }

        // Attempt to update node account ID without proper signatures
        await assertReceiptStatus(
            try await NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(AccountId(num: 3))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_DAB_NodeUpdateTransactionCanChangeNodeAccountIdToNonExistentAccountId() async throws {
        // Given / When / Then
        await assertReceiptStatus(
            try await NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(AccountId(num: 9_999_999))
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_DAB_NodeUpdateTransactionCanChangeNodeAccountIdToDeletedAccountId() async throws {
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
                .freezeWith(testEnv.client)
                .sign(accountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .accountDeleted
        )
    }

    internal func test_DAB_NodeUpdateTransactionCanChangeNodeAccountIdMissingAdminKeySignature() async throws {
        // Given
        let (newAccountId, newAccountKey) = try await createTestAccount()
        let (nonAdminOperatorId, nonAdminOperatorKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)

        _ = testEnv.client.setOperator(nonAdminOperatorId, nonAdminOperatorKey)

        addTeardownBlock { [self] in
            _ = testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)
        }

        // When / Then
        await assertReceiptStatus(
            try await NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(newAccountId)
                .freezeWith(testEnv.client)
                .sign(newAccountKey)  // Only sign with account key, not node admin key
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func test_DAB_NodeUpdateTransactionCannotRemoveAccountIdWithoutAdminKey() async throws {
        // Given
        let (newAccountId, _) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)
        let (newOperatorAccountId, newOperatorKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)

        _ = testEnv.client.setOperator(newOperatorAccountId, newOperatorKey)

        addTeardownBlock { [self] in
            _ = testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)
        }

        // When / Then
        await assertReceiptStatus(
            try await NodeUpdateTransaction()
                .nodeId(0)
                .accountId(newAccountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .invalidSignature
        )
    }

    internal func disabledTestNodeUpdateTransactionCanChangeNodeAccountUpdateAddressbookAndRetry() async throws {
        // Given
        let (newOperatorAccountId, newOperatorKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)
        let (newAccountId, newAccountKey) = try await createTestAccount(initialBalance: TestConstants.testMediumHbarBalance)

        _ = testEnv.client.setOperator(newOperatorAccountId, newOperatorKey)

        addTeardownBlock { [self] in
            _ = testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)
        }

        await testEnv.client.setNetworkUpdatePeriod(nanoseconds: nil)

        let addressBook = try await NodeAddressBookQuery()
            .setFileId(FileId.addressBook)
            .execute(testEnv.client)

        let node0 = addressBook.nodeAddresses.first(where: { $0.nodeId == 0 })!
        let oldNode0AccountId = node0.nodeAccountId

        // When
        let updateReceipt = try await NodeUpdateTransaction()
            .nodeId(0)
            .accountId(newAccountId)
            .sign(newAccountKey)
            .sign(testEnv.operator.privateKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(updateReceipt.status, .success, "Node update transaction failed")
        XCTAssertEqual(updateReceipt.nodeId, 0, "Node ID mismatch in receipt")

        // Wait for the node update to propagate to the mirror node
        try await Task.sleep(nanoseconds: 10_000_000_000)

        // Attempt to create a new account using node 0's OLD account ID, then fallback to node 4
        // This should trigger INVALID_NODE_ACCOUNT, update the address book, then retry with node 4
        let newAccountId2 = try await AccountCreateTransaction()
            .nodeAccountIds([oldNode0AccountId, AccountId(num: 4)])  // Try in order: node 0 first, then node 4
            .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .accountId

        XCTAssertNotNil(newAccountId2, "Failed to create account after INVALID_NODE_ACCOUNT retry")

        // Cleanup: Reset node 0 back to its original account ID
        do {
            _ = try await NodeUpdateTransaction()
                .nodeAccountIds([AccountId(num: 4)])  // Use a known good node
                .nodeId(0)
                .accountId(oldNode0AccountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        } catch {
            // Best effort cleanup - log but don't fail the test
            print("Warning: Failed to reset node 0 account ID: \(error)")
        }
    }
}
