// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class FileDeleteTransactionIntegrationTests: HieroIntegrationTestCase {

    private let testContent = "[swift::e2e::fileDelete]"

    // MARK: - Tests

    internal func test_Basic() async throws {
        // Given
        let fileId = try await createUnmanagedFile(
            FileCreateTransaction()
                .keys([.single(testEnv.operator.privateKey.publicKey)])
                .contents(testContent.data(using: .utf8)!)
        )

        // When
        _ = try await FileDeleteTransaction(fileId: fileId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then (deleted files report size as 0)
        try await assertFileInfo(fileId, size: 0, isDeleted: true)
    }

    internal func test_ImmutableFileFails() async throws {
        // Given
        let fileId = try await createUnmanagedFile(
            FileCreateTransaction()
                .contents(testContent.data(using: .utf8)!)
        )

        // When / Then
        await assertReceiptStatus(
            try await FileDeleteTransaction(fileId: fileId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            .unauthorized
        )
    }
}
