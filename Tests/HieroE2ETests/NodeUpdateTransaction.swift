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

        let receipt = try await Hiero.NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .declineRewards(true)
            .grpcWebProxyEndpoint(Endpoint(port: 123456, domainName: "testWebUpdated.com"))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(receipt.nodeId, 0)
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountIdToTheSameAccount() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree

        let receipt = try await Hiero.NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .accountId(AccountId(num: 3))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(receipt.status, .success)
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountId() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree

        // Create a new account with a different key to use as operator
        let key = PrivateKey.generateEd25519()

        var receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(Hbar(2))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        guard let accountId = receipt.accountId else {
            XCTFail("Failed to create new account")
            return
        }

        receipt = try await Hiero.NodeUpdateTransaction()
            .nodeAccountIds([AccountId(num: 3)])
            .nodeId(0)
            .accountId(accountId)
            .freezeWith(testEnv.client)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(receipt.status, .success, "Node update transaction failed")

        if receipt.status == .success {
            // Reset the node account ID to the original account ID
            _ = try await Hiero.NodeUpdateTransaction()
                .nodeAccountIds([AccountId(num: 4)])
                .nodeId(0)
                .accountId(AccountId(num: 3))
                .freezeWith(testEnv.client)
                .sign(key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)

            XCTAssertEqual(receipt.status, .success, "Node update transaction failed to reset node account ID")
        }
    }

    internal func testNodeUpdateTransactionCanChangeNodeAccountIdInvalidSignature() async throws {
        if shouldSkipNodeTests {
            throw XCTSkip("Node tests require special setup")
        }

        let testEnv = try TestEnvironment.nonFree

        // Create a new account with a different key to use as operator
        let newOperatorKey = PrivateKey.generateEd25519()

        let newOperatorReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newOperatorKey.publicKey))
            .initialBalance(Hbar(2))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        guard let newOperatorAccountId = newOperatorReceipt.accountId else {
            XCTFail("Failed to create new operator account")
            return
        }

        // Change the operator to the new account
        _ = testEnv.client.setOperator(newOperatorAccountId, newOperatorKey)

        addTeardownBlock {
            _ = testEnv.client.setOperator(testEnv.operator.accountId, testEnv.operator.privateKey)
        }

        // Attempt to update node account ID without proper signatures
        await assertThrowsHErrorAsync(
            try await Hiero.NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(AccountId(num: 3))
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
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

        await assertThrowsHErrorAsync(
            try await Hiero.NodeUpdateTransaction()
                .nodeId(0)
                .description("testUpdated")
                .accountId(AccountId(num: 9_999_999))
                .freezeWith(testEnv.client)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
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

        throw XCTSkip("TODO: unskip when services implements check for this")

        let testEnv = try TestEnvironment.nonFree

        let newAccountKey = PrivateKey.generateEd25519()

        let newAccountReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newAccountKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        guard let newAccountId = newAccountReceipt.accountId else {
            XCTFail("Failed to create account to delete")
            return
        }

        // Delete the account
        _ = try await AccountDeleteTransaction()
            .accountId(newAccountId)
            .transferAccountId(testEnv.operator.accountId)
            .sign(newAccountKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Attempt to update to deleted account
        let frozen = try Hiero.NodeUpdateTransaction()
            .nodeId(0)
            .description("testUpdated")
            .accountId(newAccountId)
            .freezeWith(testEnv.client)

        await assertThrowsHErrorAsync(
            try await frozen
                .sign(newAccountKey)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind,
                case .accountDeleted = status
            else {
                XCTFail("Expected ACCOUNT_DELETED, got \(error.kind)")
                return
            }
        }
    }
}
