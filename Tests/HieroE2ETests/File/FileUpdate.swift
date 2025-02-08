// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class FileUpdate: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let file = try await File.forContent("swift::e2e::fileUpdate::1]", testEnv)

        addTeardownBlock {
            try await file.delete(testEnv)
        }

        _ = try await FileUpdateTransaction()
            .fileId(file.fileId)
            .contents("updated file".data(using: .utf8)!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await FileInfoQuery(fileId: file.fileId).execute(testEnv.client)

        XCTAssertEqual(info.fileId, file.fileId)
        XCTAssertEqual(info.size, 12)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.keys, [.single(testEnv.operator.privateKey.publicKey)])
    }

    internal func testImmutableFileFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await FileCreateTransaction()
            .contents("[swift::e2e::fileUpdate::2]".data(using: .utf8)!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(receipt.fileId)

        let file = File(fileId: fileId)

        await assertThrowsHErrorAsync(
            try await FileUpdateTransaction()
                .fileId(file.fileId)
                .contents(Data([0]))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected file update to fail"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .unauthorized)
        }
    }

    internal func testMissingFileIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await FileUpdateTransaction()
                .contents("contents".data(using: .utf8)!)
                .execute(testEnv.client),
            "expected file update to fail"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidFileID)
        }
    }
}
