// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class FileUpdateTransactionIntegrationTests: HieroIntegrationTestCase {

    private let testContent = "[swift::e2e::fileUpdate]"

    // MARK: - Tests

    internal func test_Basic() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)
        let updatedContent = "updated file"

        // When
        _ = try await FileUpdateTransaction()
            .fileId(fileId)
            .contents(updatedContent.data(using: .utf8)!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        try await assertFileInfo(fileId, size: UInt64(updatedContent.count))
    }

    internal func test_ImmutableFileFails() async throws {
        // Given
        let fileId = try await createUnmanagedFile(
            FileCreateTransaction()
                .contents(testContent.data(using: .utf8)!)
        )

        // When / Then
        await assertReceiptStatus(
            try await FileUpdateTransaction()
                .fileId(fileId)
                .contents(Data([0]))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .unauthorized
        )
    }

    internal func test_MissingFileIdFails() async throws {
        // Given / When / Then
        await assertPrecheckStatus(
            try await FileUpdateTransaction()
                .contents("contents".data(using: .utf8)!)
                .execute(testEnv.client),
            .invalidFileID
        )
    }
}
