// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities
import HieroTestSupport
import XCTest

internal final class FileAppendTransactionIntegrationTests: HieroIntegrationTestCase {
    
    private let testContent = "[swift::e2e::fileAppend]"

    // MARK: - Tests

    internal func test_Basic() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)
        let contentToAppend = "update"

        // When
        _ = try await FileAppendTransaction()
            .fileId(fileId)
            .contents(contentToAppend)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        try await assertFileInfo(fileId, size: UInt64(testContent.count + contentToAppend.count))
    }

    internal func test_LargeContents() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)
        let contentToAppend = Resources.bigContents

        // When
        _ = try await FileAppendTransaction()
            .fileId(fileId)
            .contents(contentToAppend)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        try await assertFileContents(fileId, equals: testContent + contentToAppend)
        try await assertFileInfo(fileId, size: UInt64(testContent.count + contentToAppend.count))
    }
}
