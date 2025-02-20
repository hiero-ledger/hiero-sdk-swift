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
