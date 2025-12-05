// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class ClientIntegrationTests: HieroIntegrationTestCase {
    internal func test_InitWithMirrorNetwork() async throws {
        let mirrorNetworkString = "testnet.mirrornode.hedera.com:443"
        let client = try await Client.forMirrorNetwork([mirrorNetworkString])
        let mirrorNetwork = client.mirrorNetwork

        XCTAssertEqual(mirrorNetwork.count, 1)
        XCTAssertEqual(mirrorNetwork[0], mirrorNetworkString)
        XCTAssertNotNil(client.network)
    }
}
