// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TopicInfo: XCTestCase {
    internal func disabled_testQuery() async throws {
        let testEnv = try TestEnvironment.nonFree

        let topic = try await Topic.create(testEnv)

        addTeardownBlock {
            try await topic.delete(testEnv)
        }

        let info = try await TopicInfoQuery(topicId: topic.id).execute(testEnv.client)

        XCTAssertEqual(info.topicMemo, "[e2e::TopicCreateTransaction]")
    }

    internal func disabled_testQueryCost() async throws {
        let testEnv = try TestEnvironment.nonFree

        let topic = try await Topic.create(testEnv)

        addTeardownBlock {
            try await topic.delete(testEnv)
        }

        let query = TopicInfoQuery(topicId: topic.id)

        let cost = try await query.getCost(testEnv.client)

        let info = try await query.paymentAmount(cost).execute(testEnv.client)

        XCTAssertEqual(info.topicMemo, "[e2e::TopicCreateTransaction]")
    }

    internal func disabled_testQueryCostBigMax() async throws {
        let testEnv = try TestEnvironment.nonFree

        let topic = try await Topic.create(testEnv)

        addTeardownBlock {
            try await topic.delete(testEnv)
        }

        let query = TopicInfoQuery(topicId: topic.id).maxPaymentAmount(Hbar(1000))

        let cost = try await query.getCost(testEnv.client)

        let info = try await query.paymentAmount(cost).execute(testEnv.client)

        XCTAssertEqual(info.topicMemo, "[e2e::TopicCreateTransaction]")
    }

    internal func disabled_testQueryCostSmallMaxFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let topic = try await Topic.create(testEnv)

        addTeardownBlock {
            try await topic.delete(testEnv)
        }

        let query = TopicInfoQuery(topicId: topic.id).maxPaymentAmount(.fromTinybars(1))

        let cost = try await query.getCost(testEnv.client)

        await assertThrowsHErrorAsync(
            try await query.execute(testEnv.client),
            "expected error querying topic"
        ) { error in
            // note: there's a very small chance this fails if the cost of a FileContentsQuery changes right when we execute it.
            XCTAssertEqual(error.kind, .maxQueryPaymentExceeded(queryCost: cost, maxQueryPayment: .fromTinybars(1)))
        }
    }

    internal func disabled_testQueryCostInsufficientTxFeeFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let topic = try await Topic.create(testEnv)

        addTeardownBlock {
            try await topic.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await TopicInfoQuery()
                .topicId(topic.id)
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
