// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class FileContentsQueryIntegrationTests: HieroIntegrationTestCase {

    private let testContent = "[swift::e2e::fileContents]"

    // MARK: - Tests

    internal func test_Query() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)

        // When
        let contents = try await FileContentsQuery()
            .fileId(fileId)
            .execute(testEnv.client)

        // Then
        XCTAssertEqual(String(data: contents.contents, encoding: .utf8), testContent)
    }

    internal func test_QueryEmpty() async throws {
        // Given
        let fileId = try await createTestFile(contents: "")

        // When
        let contents = try await FileContentsQuery()
            .fileId(fileId)
            .execute(testEnv.client)

        // Then
        XCTAssertEqual(contents.contents, Data())
    }

    internal func test_MissingFileIdFails() async throws {
        // Given / When / Then
        await assertQueryNoPaymentPrecheckStatus(
            try await FileContentsQuery().execute(testEnv.client),
            .invalidFileID
        )
    }

    internal func test_QueryCostBigMax() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)
        let query = FileContentsQuery()
            .fileId(fileId)
            .maxPaymentAmount(10000)
        let cost = try await query.getCost(testEnv.client)

        // When
        let contents =
            try await query
            .paymentAmount(cost)
            .execute(testEnv.client)

        // Then
        XCTAssertEqual(String(data: contents.contents, encoding: .utf8), testContent)
    }

    internal func test_QueryCostSmallMaxFails() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)
        let query = FileContentsQuery()
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

    internal func test_QueryInsufficientTxFeeFails() async throws {
        // Given
        let fileId = try await createTestFile(contents: testContent)

        // When / Then
        await assertQueryPaymentPrecheckStatus(
            try await FileContentsQuery()
                .fileId(fileId)
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client),
            .insufficientTxFee
        )
    }

    internal func test_QueryFeeSchedule() async throws {
        // Given / When
        let feeScheduleBytes = try await FileContentsQuery()
            .fileId(FileId.fromString("0.0.111"))
            .execute(testEnv.client)

        // Then
        let feeSchedules = try FeeSchedules.fromBytes(feeScheduleBytes.contents)
        XCTAssertNotNil(feeSchedules.current)
    }
}
