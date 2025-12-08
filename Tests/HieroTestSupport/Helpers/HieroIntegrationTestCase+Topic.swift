// SPDX-License-Identifier: Apache-2.0

/// Topic helper methods for integration tests.
///
/// This extension provides methods for creating, registering, and asserting topics in integration tests.
/// Topics created with `createTopic` are automatically registered for cleanup at test teardown.

import Foundation
import Hiero
import XCTest

// MARK: - Topic Helpers

extension HieroIntegrationTestCase {

    // MARK: - Unmanaged Topic Creation

    /// Creates a topic from a transaction without registering it for cleanup.
    ///
    /// Use this when you need full control over the topic lifecycle or when testing
    /// scenarios where cleanup would interfere with the test (e.g., immutable topics).
    ///
    /// - Parameter transaction: Pre-configured `TopicCreateTransaction` (before execute)
    /// - Returns: The created topic ID
    public func createUnmanagedTopic(_ transaction: TopicCreateTransaction) async throws -> TopicId {
        let receipt = try await transaction.execute(testEnv.client).getReceipt(testEnv.client)
        return try XCTUnwrap(receipt.topicId)
    }

    // MARK: - Topic Registration

    /// Registers an existing topic for automatic cleanup at test teardown.
    ///
    /// - Parameters:
    ///   - topicId: The topic ID to register
    ///   - adminKey: Private key for topic deletion
    public func registerTopic(_ topicId: TopicId, adminKey: PrivateKey) async {
        await registerTopic(topicId, adminKeys: [adminKey])
    }

    /// Registers an existing topic for automatic cleanup at test teardown (multiple keys).
    ///
    /// - Parameters:
    ///   - topicId: The topic ID to register
    ///   - adminKeys: Private keys required for topic deletion
    public func registerTopic(_ topicId: TopicId, adminKeys: [PrivateKey]) async {
        await resourceManager.registerCleanup(priority: .topics) { [client = testEnv.client] in
            let transaction = TopicDeleteTransaction().topicId(topicId)
            for key in adminKeys {
                transaction.sign(key)
            }
            _ = try await transaction.execute(client).getReceipt(client)
        }
    }

    // MARK: - Managed Topic Creation

    /// Creates a topic and registers it for automatic cleanup.
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `TopicCreateTransaction` (before execute)
    ///   - adminKey: Private key for topic deletion
    /// - Returns: The created topic ID
    public func createTopic(
        _ transaction: TopicCreateTransaction,
        adminKey: PrivateKey
    ) async throws -> TopicId {
        try await createTopic(transaction, adminKeys: [adminKey])
    }

    /// Creates a topic and registers it for automatic cleanup (multiple keys).
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `TopicCreateTransaction` (before execute)
    ///   - adminKeys: Private keys required for topic deletion
    /// - Returns: The created topic ID
    public func createTopic(
        _ transaction: TopicCreateTransaction,
        adminKeys: [PrivateKey]
    ) async throws -> TopicId {
        let topicId = try await createUnmanagedTopic(transaction)
        await registerTopic(topicId, adminKeys: adminKeys)
        return topicId
    }

    // MARK: - Convenience Topic Creation

    /// Creates a standard topic with operator's admin key and standard memo.
    ///
    /// This is the primary convenience method for creating topics in tests.
    ///
    /// - Returns: The created topic ID
    public func createStandardTopic() async throws -> TopicId {
        try await createTopic(
            TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .topicMemo(TestConstants.standardTopicMemo),
            adminKey: testEnv.operator.privateKey
        )
    }

    /// Creates an immutable topic (no admin key, cannot be deleted).
    ///
    /// Note: This creates an unmanaged topic since immutable topics cannot be cleaned up.
    ///
    /// - Returns: The created topic ID
    public func createImmutableTopic() async throws -> TopicId {
        try await createUnmanagedTopic(TopicCreateTransaction())
    }

    /// Creates a topic with operator admin key but no memo.
    ///
    /// - Returns: The created topic ID
    public func createTopicWithOperatorAdmin() async throws -> TopicId {
        try await createTopic(
            TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey)),
            adminKey: testEnv.operator.privateKey
        )
    }

    // MARK: - TopicInfo Assertions

    /// Asserts standard topic info properties.
    ///
    /// - Parameters:
    ///   - info: Topic info to validate
    ///   - topicId: Expected topic ID
    ///   - memo: Expected memo (default: TestConstants.standardTopicMemo)
    public func assertStandardTopicInfo(
        _ info: TopicInfo,
        topicId: TopicId,
        memo: String = TestConstants.standardTopicMemo,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(info.topicId, topicId, "Topic ID mismatch", file: file, line: line)
        XCTAssertEqual(info.topicMemo, memo, "Topic memo mismatch", file: file, line: line)
    }
}
