// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TopicInfoQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_Query() async throws {
        // Given
        let topicId = try await createStandardTopic()

        // When
        let info = try await TopicInfoQuery(topicId: topicId).execute(testEnv.client)

        // Then
        XCTAssertEqual(info.topicMemo, TestConstants.standardTopicMemo)
    }

    internal func test_QueryCost() async throws {
        // Given
        let topicId = try await createStandardTopic()
        let query = TopicInfoQuery(topicId: topicId)
        let cost = try await query.getCost(testEnv.client)

        // When
        let info = try await query.paymentAmount(cost).execute(testEnv.client)

        // Then
        XCTAssertEqual(info.topicMemo, TestConstants.standardTopicMemo)
    }

    internal func test_QueryCostBigMax() async throws {
        // Given
        let topicId = try await createStandardTopic()
        let query = TopicInfoQuery(topicId: topicId).maxPaymentAmount(Hbar(1000))
        let cost = try await query.getCost(testEnv.client)

        // When
        let info = try await query.paymentAmount(cost).execute(testEnv.client)

        // Then
        XCTAssertEqual(info.topicMemo, TestConstants.standardTopicMemo)
    }

    internal func test_QueryCostSmallMaxFails() async throws {
        // Given
        let topicId = try await createStandardTopic()
        let query = TopicInfoQuery(topicId: topicId).maxPaymentAmount(.fromTinybars(1))
        let cost = try await query.getCost(testEnv.client)

        // When / Then
        await assertThrowsHErrorAsync(
            try await query.execute(testEnv.client),
            "expected error querying topic"
        ) { error in
            XCTAssertEqual(error.kind, .maxQueryPaymentExceeded(queryCost: cost, maxQueryPayment: .fromTinybars(1)))
        }
    }

    internal func disabledTestQueryCostInsufficientTxFeeFails() async throws {
        // Given
        let topicId = try await createStandardTopic()

        // When / Then
        await assertThrowsHErrorAsync(
            try await TopicInfoQuery()
                .topicId(topicId)
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
