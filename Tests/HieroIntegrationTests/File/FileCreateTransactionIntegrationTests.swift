// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class FileCreateTransactionIntegrationTests: HieroIntegrationTestCase {

    private let testContent = "[swift::e2e::fileCreate]"

    // MARK: - Tests

    internal func test_Basic() async throws {
        // Given / When
        let fileId = try await createFile(
            FileCreateTransaction()
                .keys([.single(testEnv.operator.privateKey.publicKey)])
                .contents(testContent.data(using: .utf8)!),
            key: testEnv.operator.privateKey
        )

        // Then
        try await assertFileInfo(fileId, size: UInt64(testContent.count))
    }

    internal func test_EmptyFile() async throws {
        // Given / When
        let fileId = try await createFile(
            FileCreateTransaction()
                .keys([.single(testEnv.operator.privateKey.publicKey)]),
            key: testEnv.operator.privateKey
        )

        // Then
        try await assertFileInfo(fileId, size: 0)
    }

    internal func test_NoKeys() async throws {
        // Given / When
        let fileId = try await createUnmanagedFile(FileCreateTransaction())

        // Then
        try await assertFileInfo(fileId, size: 0, hasKeys: false)
    }
}
