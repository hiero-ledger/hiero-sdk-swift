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

internal final class FileContents: XCTestCase {
    internal func testQuery() async throws {
        let testEnv = try TestEnvironment.nonFree

        let file = try await File.forContent("[swift::e2e::fileContents::1]", testEnv)

        addTeardownBlock {
            try await file.delete(testEnv)
        }

        let contents = try await FileContentsQuery().fileId(file.fileId).execute(testEnv.client)

        XCTAssertEqual(String(data: contents.contents, encoding: .utf8), "[swift::e2e::fileContents::1]")
    }

    internal func testQueryEmpty() async throws {
        let testEnv = try TestEnvironment.nonFree

        let file = try await File.forContent("", testEnv)

        addTeardownBlock {
            try await file.delete(testEnv)
        }

        let contents = try await FileContentsQuery().fileId(file.fileId).execute(testEnv.client)
        XCTAssertEqual(contents.contents, Data())
    }

    internal func testMissingFileIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await FileContentsQuery().execute(testEnv.client)
        ) { error in
            guard case .queryNoPaymentPreCheckStatus(let status) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryNoPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidFileID)
        }
    }

    internal func testQueryCostBigMax() async throws {
        let testEnv = try TestEnvironment.nonFree

        let file = try await File.forContent("[swift::e2e::fileContents::2]", testEnv)

        addTeardownBlock {
            try await file.delete(testEnv)
        }

        let query = FileContentsQuery().fileId(file.fileId).maxPaymentAmount(10000)

        let cost = try await query.getCost(testEnv.client)

        let contents = try await query.paymentAmount(cost).execute(testEnv.client)

        XCTAssertEqual(String(data: contents.contents, encoding: .utf8), "[swift::e2e::fileContents::2]")
    }

    internal func testQueryCostSmallMaxFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let file = try await File.forContent("[swift::e2e::fileContents::3]", testEnv)

        addTeardownBlock {
            try await file.delete(testEnv)
        }

        let query = FileContentsQuery().fileId(file.fileId).maxPaymentAmount(.fromTinybars(1))

        let cost = try await query.getCost(testEnv.client)

        await assertThrowsHErrorAsync(
            try await query.execute(testEnv.client),
            "expected error querying contract"
        ) { error in
            // note: there's a very small chance this fails if the cost of a FileContentsQuery changes right when we execute it.
            XCTAssertEqual(error.kind, .maxQueryPaymentExceeded(queryCost: cost, maxQueryPayment: .fromTinybars(1)))
        }
    }

    internal func testQueryInsufficientTxFeeFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let file = try await File.forContent("[swift::e2e::fileContents::4]", testEnv)

        addTeardownBlock {
            try await file.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await FileContentsQuery()
                .fileId(file.fileId)
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client)
        ) { error in
            guard case .queryPaymentPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .insufficientTxFee)
        }
    }
}
