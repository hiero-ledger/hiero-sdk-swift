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

internal final class FileDelete: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let file = try await File.forContent("[swift::e2e::fileDelete::1]", testEnv)

        _ = try await FileDeleteTransaction(fileId: file.fileId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let info = try await FileInfoQuery(fileId: file.fileId).execute(testEnv.client)

        XCTAssertTrue(info.isDeleted)
    }

    internal func testImmutableFileFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await FileCreateTransaction()
            .contents("[e2e::FileCreateTransaction]".data(using: .utf8)!)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(receipt.fileId)

        let info = try await FileInfoQuery()
            .fileId(fileId)
            .execute(testEnv.client)

        XCTAssertEqual(info.fileId, fileId)
        XCTAssertEqual(info.size, 28)
        XCTAssertEqual(info.isDeleted, false)
        XCTAssertEqual(info.keys, KeyList.init(keys: []))

        let file = File(fileId: fileId)

        await assertThrowsHErrorAsync(
            try await FileDeleteTransaction()
                .fileId(file.fileId)
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
}
