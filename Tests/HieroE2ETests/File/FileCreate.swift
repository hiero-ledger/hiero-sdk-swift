// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class FileCreate: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await FileCreateTransaction()
            .keys([.single(testEnv.operator.privateKey.publicKey)])
            .contents("[swift::e2e::createFile]".data(using: .utf8)!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(receipt.fileId)

        let file = File(fileId: fileId)

        addTeardownBlock {
            try await file.delete(testEnv)
        }

        let info = try await FileInfoQuery(fileId: fileId).execute(testEnv.client)

        XCTAssertEqual(info.fileId, fileId)
        XCTAssertEqual(info.size, 24)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.keys, [.single(testEnv.operator.privateKey.publicKey)])
    }

    internal func testEmptyFile() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await FileCreateTransaction()
            .keys([.single(testEnv.operator.privateKey.publicKey)])
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(receipt.fileId)

        let file = File(fileId: fileId)

        addTeardownBlock {
            try await file.delete(testEnv)
        }

        let info = try await FileInfoQuery(fileId: fileId).execute(testEnv.client)

        XCTAssertEqual(info.fileId, fileId)
        XCTAssertEqual(info.size, 0)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.keys, [.single(testEnv.operator.privateKey.publicKey)])
    }

    internal func testNoKeys() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await FileCreateTransaction()
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(receipt.fileId)

        let info = try await FileInfoQuery(fileId: fileId).execute(testEnv.client)

        XCTAssertEqual(info.fileId, fileId)
        XCTAssertEqual(info.size, 0)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.keys, [])
    }
}
