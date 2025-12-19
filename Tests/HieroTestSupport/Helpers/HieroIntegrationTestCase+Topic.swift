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
    /// - Parameters:
    ///   - transaction: Pre-configured `TopicCreateTransaction` (before execute)
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created topic ID
    public func createUnmanagedTopic(_ transaction: TopicCreateTransaction, useAdminClient: Bool = false) async throws
        -> TopicId
    {
        let receipt =
            try await transaction
            .execute(useAdminClient ? testEnv.adminClient : testEnv.client)
            .getReceipt(useAdminClient ? testEnv.adminClient : testEnv.client)
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
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created topic ID
    public func createTopic(
        _ transaction: TopicCreateTransaction,
        adminKey: PrivateKey,
        useAdminClient: Bool = false
    ) async throws -> TopicId {
        try await createTopic(transaction, adminKeys: [adminKey], useAdminClient: useAdminClient)
    }

    /// Creates a topic and registers it for automatic cleanup (multiple keys).
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `TopicCreateTransaction` (before execute)
    ///   - adminKeys: Private keys required for topic deletion
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created topic ID
    public func createTopic(
        _ transaction: TopicCreateTransaction,
        adminKeys: [PrivateKey],
        useAdminClient: Bool = false
    ) async throws -> TopicId {
        let topicId = try await createUnmanagedTopic(transaction, useAdminClient: useAdminClient)
        await registerTopic(topicId, adminKeys: adminKeys)
        return topicId
    }

    // MARK: - Convenience Topic Creation

    /// Creates a standard topic with operator's admin key and standard memo.
    ///
    /// This is the primary convenience method for creating topics in tests.
    ///
    /// - Parameter useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created topic ID
    public func createStandardTopic(useAdminClient: Bool = false) async throws -> TopicId {
        try await createTopic(
            TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey))
                .topicMemo(TestConstants.standardTopicMemo),
            adminKey: testEnv.operator.privateKey,
            useAdminClient: useAdminClient
        )
    }

    /// Creates an immutable topic (no admin key, cannot be deleted).
    ///
    /// Note: This creates an unmanaged topic since immutable topics cannot be cleaned up.
    ///
    /// - Parameter useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created topic ID
    public func createImmutableTopic(useAdminClient: Bool = false) async throws -> TopicId {
        try await createUnmanagedTopic(TopicCreateTransaction(), useAdminClient: useAdminClient)
    }

    /// Creates a topic with operator admin key but no memo.
    ///
    /// - Parameter useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created topic ID
    public func createTopicWithOperatorAdmin(useAdminClient: Bool = false) async throws -> TopicId {
        try await createTopic(
            TopicCreateTransaction()
                .adminKey(.single(testEnv.operator.privateKey.publicKey)),
            adminKey: testEnv.operator.privateKey,
            useAdminClient: useAdminClient
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
