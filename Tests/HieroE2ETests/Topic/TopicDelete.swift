// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TopicDelete: XCTestCase {
    internal func disabledTestBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let topic = try await Topic.create(testEnv)

        _ = try await TopicDeleteTransaction()
            .topicId(topic.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func disabledTestImmutableFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let receipt = try await TopicCreateTransaction()
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(receipt.topicId)

        await assertThrowsHErrorAsync(
            try await TopicDeleteTransaction()
                .topicId(topicId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected topic delete to fail"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .unauthorized)
        }
    }

    internal func disabledTestWrongAdminKeyFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let adminKey = PrivateKey.generateEd25519()

        let receipt = try await TopicCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .sign(adminKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let topicId = try XCTUnwrap(receipt.topicId)

        await assertThrowsHErrorAsync(
            try await TopicDeleteTransaction()
                .topicId(topicId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected topic delete to fail"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }
}
