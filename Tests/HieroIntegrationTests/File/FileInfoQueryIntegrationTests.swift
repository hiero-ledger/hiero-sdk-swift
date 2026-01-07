// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class FileInfoQueryIntegrationTests: HieroIntegrationTestCase {

    private let testContent = "[swift::e2e::fileInfo]"

    // MARK: - Tests

    internal func test_Query() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)

        // When
        let info = try await FileInfoQuery()
            .fileId(fileId)
            .execute(testEnv.client)

        // Then
        XCTAssertEqual(info.fileId, fileId)
        XCTAssertEqual(info.size, UInt64(testContent.count))
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.keys, [.single(testEnv.operator.privateKey.publicKey)])
    }

    internal func test_QueryEmptyNoAdminKey() async throws {
        // Given
        let fileId = try await createUnmanagedFile(FileCreateTransaction())

        // When
        let info = try await FileInfoQuery()
            .fileId(fileId)
            .execute(testEnv.client)

        // Then
        XCTAssertEqual(info.fileId, fileId)
        XCTAssertEqual(info.size, 0)
        XCTAssertFalse(info.isDeleted)
        XCTAssertEqual(info.keys, [])
    }

    internal func test_QueryCostBigMax() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)
        let query = FileInfoQuery()
            .fileId(fileId)
            .maxPaymentAmount(Hbar(1000))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        _ =
            try await query
            .paymentAmount(cost)
            .execute(testEnv.client)
    }

    internal func test_QueryCostSmallMaxFails() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)
        let query = FileInfoQuery()
            .fileId(fileId)
            .maxPaymentAmount(.fromTinybars(1))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        await assertMaxQueryPaymentExceeded(
            try await query.execute(testEnv.client),
            queryCost: cost,
            maxQueryPayment: .fromTinybars(1)
        )
    }

    internal func test_QueryCostInsufficientTxFeeFails() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)

        // When / Then
        await assertQueryPaymentPrecheckStatus(
            try await FileInfoQuery()
                .fileId(fileId)
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client),
            .insufficientTxFee
        )
    }
}
