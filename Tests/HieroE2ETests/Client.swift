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

internal class ClientIntegrationTests: XCTestCase {
    internal func testInitWithMirrorNetwork() async throws {
        let mirrorNetworkString = "testnet.mirrornode.hedera.com:443"
        let client = try await Client.forMirrorNetwork([mirrorNetworkString])
        let mirrorNetwork = client.mirrorNetwork

        XCTAssertEqual(mirrorNetwork.count, 1)
        XCTAssertEqual(mirrorNetwork[0], mirrorNetworkString)
        XCTAssertNotNil(client.network)
    }
}
