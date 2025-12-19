// SPDX-License-Identifier: Apache-2.0

/// File helper methods for integration tests.
///
/// This extension provides methods for creating, registering, and asserting files in integration tests.
/// Files created with `createFile` are automatically registered for cleanup at test teardown.

import Foundation
import Hiero
import XCTest

// MARK: - File Helpers

extension HieroIntegrationTestCase {

    // MARK: - Unmanaged File Creation

    /// Creates a file from a transaction without registering it for cleanup.
    ///
    /// Use this when you need full control over the file lifecycle or when testing
    /// scenarios where cleanup would interfere with the test.
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `FileCreateTransaction` (before execute)
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created file ID
    public func createUnmanagedFile(_ transaction: FileCreateTransaction, useAdminClient: Bool = false) async throws
        -> FileId
    {
        let receipt =
            try await transaction
            .execute(useAdminClient ? testEnv.adminClient : testEnv.client)
            .getReceipt(useAdminClient ? testEnv.adminClient : testEnv.client)
        return try XCTUnwrap(receipt.fileId)
    }

    // MARK: - File Registration

    /// Registers an existing file for automatic cleanup at test teardown.
    ///
    /// - Parameters:
    ///   - fileId: The file ID to register
    ///   - key: Private key for file deletion
    public func registerFile(_ fileId: FileId, key: PrivateKey) async {
        await registerFile(fileId, keys: [key])
    }

    /// Registers an existing file for automatic cleanup at test teardown (multiple keys).
    ///
    /// - Parameters:
    ///   - fileId: The file ID to register
    ///   - keys: Private keys required for file deletion
    public func registerFile(_ fileId: FileId, keys: [PrivateKey]) async {
        await resourceManager.registerCleanup(priority: .files) { [client = testEnv.client] in
            let transaction = FileDeleteTransaction(fileId: fileId)
            for key in keys {
                transaction.sign(key)
            }
            _ = try await transaction.execute(client).getReceipt(client)
        }
    }

    // MARK: - Managed File Creation

    /// Creates a file and registers it for automatic cleanup.
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `FileCreateTransaction` (before execute)
    ///   - key: Private key for file deletion
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created file ID
    public func createFile(
        _ transaction: FileCreateTransaction,
        key: PrivateKey,
        useAdminClient: Bool = false
    ) async throws -> FileId {
        try await createFile(transaction, keys: [key], useAdminClient: useAdminClient)
    }

    /// Creates a file and registers it for automatic cleanup (multiple keys).
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `FileCreateTransaction` (before execute)
    ///   - keys: Private keys required for file deletion
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created file ID
    public func createFile(
        _ transaction: FileCreateTransaction,
        keys: [PrivateKey],
        useAdminClient: Bool = false
    ) async throws -> FileId {
        let fileId = try await createUnmanagedFile(transaction, useAdminClient: useAdminClient)
        await registerFile(fileId, keys: keys)
        return fileId
    }

    // MARK: - Convenience File Creation

    /// Creates a test file with standard operator key and the given content.
    ///
    /// This is the primary convenience method for creating files in tests.
    ///
    /// - Parameters:
    ///   - contents: String content for the file
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created file ID
    public func createTestFile(contents: String, useAdminClient: Bool = false) async throws -> FileId {
        try await createFile(
            FileCreateTransaction()
                .keys([.single(testEnv.operator.privateKey.publicKey)])
                .contents(contents.data(using: .utf8)!),
            key: testEnv.operator.privateKey,
            useAdminClient: useAdminClient
        )
    }

    // MARK: - FileInfo Assertions

    /// Asserts that file info matches expected values.
    ///
    /// - Parameters:
    ///   - fileId: File ID to query
    ///   - size: Expected file size
    ///   - isDeleted: Expected deletion status (default: false)
    ///   - hasKeys: Whether file should have operator keys (default: true)
    public func assertFileInfo(
        _ fileId: FileId,
        size: UInt64,
        isDeleted: Bool = false,
        hasKeys: Bool = true
    ) async throws {
        let info = try await FileInfoQuery()
            .fileId(fileId)
            .execute(testEnv.client)

        XCTAssertEqual(info.fileId, fileId)
        XCTAssertEqual(info.size, size)
        XCTAssertEqual(info.isDeleted, isDeleted)
        XCTAssertEqual(info.keys, hasKeys ? [.single(testEnv.operator.privateKey.publicKey)] : [])
    }

    // MARK: - FileContents Assertions

    /// Asserts that file contents match expected string.
    ///
    /// - Parameters:
    ///   - fileId: File ID to query
    ///   - expected: Expected string content
    public func assertFileContents(_ fileId: FileId, equals expected: String) async throws {
        let response = try await FileContentsQuery()
            .fileId(fileId)
            .execute(testEnv.client)

        XCTAssertEqual(String(data: response.contents, encoding: .utf8)!, expected)
    }

    /// Asserts that file contents match expected data.
    ///
    /// - Parameters:
    ///   - fileId: File ID to query
    ///   - expected: Expected data content
    public func assertFileContents(_ fileId: FileId, equals expected: Data) async throws {
        let response = try await FileContentsQuery()
            .fileId(fileId)
            .execute(testEnv.client)

        XCTAssertEqual(response.contents, expected)
    }
}
