// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal struct Topic {
    internal let id: TopicId
    internal static func create(_ testEnv: NonfreeTestEnvironment) async throws -> Self {
        let receipt = try await TopicCreateTransaction()
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .topicMemo("[e2e::TopicCreateTransaction]")
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        return Self(id: try XCTUnwrap(receipt.topicId))
    }

    internal func delete(_ testEnv: NonfreeTestEnvironment) async throws {
        _ = try await TopicDeleteTransaction()
            .topicId(self.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }
}
