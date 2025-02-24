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

import Foundation
import Hiero
import XCTest

internal struct File {
    internal let fileId: FileId

    /// Creates a file with the given content.
    internal static func forContent(_ content: Data, _ testEnv: NonfreeTestEnvironment) async throws -> Self {
        try await testEnv.ratelimits.file()

        let receipt = try await FileCreateTransaction()
            .keys([.single(testEnv.operator.privateKey.publicKey)])
            .contents(content)
            .expirationTime(.now + .days(30))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(receipt.fileId)

        return Self(fileId: fileId)
    }

    internal static func forContent(_ content: String, _ testEnv: NonfreeTestEnvironment) async throws -> Self {
        try await forContent(content.data(using: .utf8)!, testEnv)
    }

    internal func delete(_ testEnv: NonfreeTestEnvironment) async throws {
        try await testEnv.ratelimits.file()

        _ = try await FileDeleteTransaction(fileId: fileId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

    }
}
