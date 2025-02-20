/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

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
