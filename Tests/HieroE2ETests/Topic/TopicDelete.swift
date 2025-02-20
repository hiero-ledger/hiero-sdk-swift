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

internal class TopicDelete: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        let topic = try await Topic.create(testEnv)

        _ = try await TopicDeleteTransaction()
            .topicId(topic.id)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testImmutableFails() async throws {
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

    internal func testWrongAdminKeyFails() async throws {
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
