// SPDX-License-Identifier: Apache-2.0

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

    internal func disabledTestQueryInsufficientTxFeeFails() async throws {
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
