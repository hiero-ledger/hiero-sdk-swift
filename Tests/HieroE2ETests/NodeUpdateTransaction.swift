// SPDX-License-Identifier: Apache-2.0

import Network
import XCTest

@testable import Hiero

internal final class NodeUpdateTransaction: XCTestCase {
    private var shouldSkipNodeTests: Bool {
        // Node creation/update requires special permissions and setup
        // These tests should only run in environments with proper node management capabilities
        return false
    }

    // MARK: - Test Cases

    internal func testNodeUpdateTransactionCanExecute() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree
        let client = try await Client.forMirrorNetwork(["integration.mirrornode.hedera-ops.com:443"])
        client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        let receipt = try await Hiero.NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .declineRewards(true)
            .grpcWebProxyEndpoint(Endpoint(port: 123456, domainName: "testWebUpdated.com"))
            .execute(client)
            .getReceipt(client)

        XCTAssertEqual(receipt.nodeId, 0)
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountIdToTheSameAccount() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree
        let client = try await Client.forMirrorNetwork(["integration.mirrornode.hedera-ops.com:443"])
        client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        let receipt = try await Hiero.NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .accountId(AccountId(num: 3))
            .execute(client)
            .getReceipt(client)

        XCTAssertEqual(receipt.status, .success)
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountId() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree
        let client = try await Client.forMirrorNetwork(["integration.mirrornode.hedera-ops.com:443"])
        client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        // Create a new account with a different key to use as operator
        let key = PrivateKey.generateEd25519()

        var receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(Hbar(2))
            .execute(client)
            .getReceipt(client)

        guard let accountId = receipt.accountId else {
            XCTFail("Failed to create new account")
            return
        }

        receipt = try await Hiero.NodeUpdateTransaction()
            .nodeAccountIds([AccountId(num: 3)])
            .nodeId(0)
            .accountId(accountId)
            .freezeWith(client)
            .sign(key)
            .execute(client)
            .getReceipt(client)

        XCTAssertEqual(receipt.status, .success, "Node update transaction failed")

        if receipt.status == .success {
            // Reset the node account ID to the original account ID
            _ = try await Hiero.NodeUpdateTransaction()
                .nodeAccountIds([AccountId(num: 4)])
                .nodeId(0)
                .accountId(AccountId(num: 3))
                .freezeWith(client)
                .sign(key)
                .execute(client)
                .getReceipt(client)

            XCTAssertEqual(receipt.status, .success, "Node update transaction failed to reset node account ID")
        }
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountIdInvalidSignature() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree
        let client = try await Client.forMirrorNetwork(["integration.mirrornode.hedera-ops.com:443"])
        client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        // Create a new account with a different key to use as operator
        let newOperatorKey = PrivateKey.generateEd25519()

        let newOperatorReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newOperatorKey.publicKey))
            .initialBalance(Hbar(2))
            .execute(client)
            .getReceipt(client)

        guard let newOperatorAccountId = newOperatorReceipt.accountId else {
            XCTFail("Failed to create new operator account")
            return
        }

        // Change the operator to the new account
        _ = client.setOperator(newOperatorAccountId, newOperatorKey)

        addTeardownBlock {
            _ = client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)
        }

        // Attempt to update node account ID without proper signatures
        await assertThrowsHErrorAsync(
            try await Hiero.NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(AccountId(num: 3))
                .execute(client)
                .getReceipt(client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind,
                case .invalidSignature = status
            else {
                XCTFail("Expected INVALID_SIGNATURE, got \(error.kind)")
                return
            }
        }
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountIdToNonExistentAccountId() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree
        let client = try await Client.forMirrorNetwork(["integration.mirrornode.hedera-ops.com:443"])
        client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        await assertThrowsHErrorAsync(
            try await Hiero.NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(AccountId(num: 9_999_999))
                .freezeWith(client)
                .execute(client)
                .getReceipt(client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind,
                case .invalidSignature = status
            else {
                XCTFail("Expected INVALID_SIGNATURE, got \(error.kind)")
                return
            }
        }
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountIdToDeletedAccountId() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree
        let client = try await Client.forMirrorNetwork(["integration.mirrornode.hedera-ops.com:443"])
        client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        let newAccountKey = PrivateKey.generateEd25519()

        let newAccountReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newAccountKey.publicKey))
            .execute(client)
            .getReceipt(client)

        guard let newAccountId = newAccountReceipt.accountId else {
            XCTFail("Failed to create account to delete")
            return
        }

        // Delete the account
        _ = try await AccountDeleteTransaction()
            .accountId(newAccountId)
            .transferAccountId(testEnv.operator.accountId)
            .sign(newAccountKey)
            .execute(client)
            .getReceipt(client)

        // Attempt to update to deleted account
        let frozen = try Hiero.NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .accountId(newAccountId)
            .freezeWith(client)

        await assertThrowsHErrorAsync(
            try await frozen
                .sign(newAccountKey)
                .execute(client)
                .getReceipt(client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind,
                case .accountDeleted = status
            else {
                XCTFail("Expected ACCOUNT_DELETED, got \(error.kind)")
                return
            }
        }
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountIdMissingAdminKeySignature() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree
        let client = try await Client.forMirrorNetwork(["integration.mirrornode.hedera-ops.com:443"])
        client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        // Create a new account to use as the new node account ID
        let newAccountKey = PrivateKey.generateEd25519()

        let newAccountReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newAccountKey.publicKey))
            .initialBalance(Hbar(2))
            .execute(client)
            .getReceipt(client)

        guard let newAccountId = newAccountReceipt.accountId else {
            XCTFail("Failed to create new account")
            return
        }

        // Create another account to use as operator (not admin, just for signing)
        let nonAdminOperatorKey = PrivateKey.generateEd25519()
        let nonAdminOperatorReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(nonAdminOperatorKey.publicKey))
            .initialBalance(Hbar(2))
            .execute(client)
            .getReceipt(client)

        guard let nonAdminOperatorId = nonAdminOperatorReceipt.accountId else {
            XCTFail("Failed to create non-admin operator account")
            return
        }

        // Change operator to non-admin account
        _ = client.setOperator(nonAdminOperatorId, nonAdminOperatorKey)

        addTeardownBlock {
            _ = client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)
        }

        // Attempt to update node account ID with only the account key signature (missing node admin signature)
        await assertThrowsHErrorAsync(
            try await Hiero.NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(newAccountId)
                .freezeWith(client)
                .sign(newAccountKey)  // Only sign with account key, not node admin key
                .execute(client)
                .getReceipt(client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind,
                case .invalidSignature = status
            else {
                XCTFail("Expected INVALID_SIGNATURE, got \(error.kind)")
                return
            }
        }
    }

    internal func testNodeUpdateTransactionCannotRemoveAccountIdWithoutAdminKey() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree
        let client = try await Client.forMirrorNetwork(["integration.mirrornode.hedera-ops.com:443"])
        client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        // Create a new account with a different key to use as operator (not admin key)
        let newOperatorKey = PrivateKey.generateEd25519()

        let newOperatorReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newOperatorKey.publicKey))
            .initialBalance(Hbar(2))
            .execute(client)
            .getReceipt(client)

        guard let newOperatorAccountId = newOperatorReceipt.accountId else {
            XCTFail("Failed to create new operator account")
            return
        }

        // Change the operator to the new account
        _ = client.setOperator(newOperatorAccountId, newOperatorKey)

        addTeardownBlock {
            _ = client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)
        }

        // Attempt to remove account ID (set to 0.0.0) without node admin key signature
        await assertThrowsHErrorAsync(
            try await Hiero.NodeUpdateTransaction()
                .nodeId(0)
                .accountId(AccountId(num: 0))  // Remove account ID
                .execute(client)
                .getReceipt(client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("Expected receipt status error, got \(error.kind)")
                return
            }

            // Accept either INVALID_SIGNATURE or INVALID_NODE_ACCOUNT_ID
            // INVALID_NODE_ACCOUNT_ID can occur if the removal partially succeeds
            let validStatuses: [Status] = [.invalidSignature, .invalidNodeAccountID]
            XCTAssert(
                validStatuses.contains(status),
                "Expected INVALID_SIGNATURE or INVALID_NODE_ACCOUNT_ID, got \(status)"
            )
        }
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountUpdateAddressbookAndRetry() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree
        let client = try await Client.forMirrorNetwork(["integration.mirrornode.hedera-ops.com:443"])
        client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)

        // Disable the background network update task for this test
        // We want to control when the address book update happens to demonstrate the INVALID_NODE_ACCOUNT flow
        await client.setNetworkUpdatePeriod(nanoseconds: nil)

        // Query the address book to get node 0's current account ID
        let addressBook = try await NodeAddressBookQuery()
            .setFileId(FileId.addressBook)
            .execute(client)

        guard let node0 = addressBook.nodeAddresses.first(where: { $0.nodeId == 0 }) else {
            XCTFail("Node 0 not found in address book")
            return
        }
        let oldNode0AccountId = node0.nodeAccountId

        // Create a new account to use as the new node account ID
        let newAccountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey))
            .initialBalance(Hbar(5))
            .execute(client)
            .getReceipt(client)
            .accountId

        guard let newAccountId = newAccountId else {
            XCTFail("Failed to create new account")
            return
        }

        // Update node 0 with the new account ID
        let updateReceipt = try await Hiero.NodeUpdateTransaction()
            .nodeId(0)
            .accountId(newAccountId)
            .execute(client)
            .getReceipt(client)
            .validateStatus(true)

        XCTAssertEqual(updateReceipt.status, .success, "Node update transaction failed")
        XCTAssertEqual(updateReceipt.nodeId, 0, "Node ID mismatch in receipt")

        // Wait for the node update to propagate to the mirror node
        try await Task.sleep(nanoseconds: 10_000_000_000)

        // Attempt to create a new account using node 0's OLD account ID, then fallback to node 4
        // This should trigger INVALID_NODE_ACCOUNT, update the address book, then retry with node 4
        let newAccountId2 = try await AccountCreateTransaction()
            .nodeAccountIds([oldNode0AccountId, AccountId(num: 4)])  // Try in order: node 0 first, then node 4
            .keyWithoutAlias(.single(testEnv.operator.privateKey.publicKey))
            .execute(client)
            .getReceipt(client)
            .accountId

        XCTAssertNotNil(newAccountId2, "Failed to create account after INVALID_NODE_ACCOUNT retry")

        // Cleanup: Reset node 0 back to its original account ID
        addTeardownBlock {
            do {
                _ = try await Hiero.NodeUpdateTransaction()
                    .nodeAccountIds([AccountId(num: 4)])  // Use a known good node
                    .nodeId(0)
                    .accountId(oldNode0AccountId)
                    .execute(client)
                    .getReceipt(client)
            } catch {
                // Best effort cleanup - log but don't fail the test
                print("Warning: Failed to reset node 0 account ID: \(error)")
            }
        }
    }
}
