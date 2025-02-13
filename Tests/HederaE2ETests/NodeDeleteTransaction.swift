/*
 * ‌
 * Hedera Swift SDK
 *
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 *
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
 *
 */

import Hedera
import XCTest

internal class NodeDelete: XCTestCase {
    private var shouldSkipTest: Bool {
        return true
    }

    internal let testNodeId: UInt64 = 2
    internal let testFileId: FileId = FileId(150)

    // File hash taken from network (change this to match)
    internal let testFileHash: String =
        "f933337c1585674b4e273072f48b140fc0aa81aea962c8cfa1f0cef5e04981bcd7c596c1df0ec6a26f0610940a5de5f9"

    internal func testNodeDelete() async throws {
        if shouldSkipTest {
            throw XCTSkip("Temporarily disabled to pass CI; awaiting Solo service CI integration")
        }

        let testEnv = try TestEnvironment.nonFree

        let fileHashBytes = testFileHash.data(using: .utf8)!

        _ = try await NodeDeleteTransaction()
            .nodeId(testNodeId)
            .freezeWith(testEnv.client)
            .execute(testEnv.client)

        _ = try await FreezeTransaction()
            .freezeType(FreezeType.prepareUpgrade)
            .fileId(testFileId)
            .fileHash(fileHashBytes)
            .freezeWith(testEnv.client)
            .execute(testEnv.client)

        let response = try await FreezeTransaction()
            .freezeType(FreezeType.freezeUpgrade)
            .startTime(.now + .seconds(5))
            .fileId(testFileId)
            .fileHash(fileHashBytes)
            .freezeWith(testEnv.client)
            .execute(testEnv.client)

        let _ = try await response.getReceipt(testEnv.client)
    }

}
