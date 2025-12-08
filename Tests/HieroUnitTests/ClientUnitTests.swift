// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ClientUnitTests: HieroUnitTestCase {
    internal func test_GetShardRealm() throws {
        let shard: UInt64 = 1
        let realm: UInt64 = 2
        let client = try Client.forNetwork([String: AccountId](), shard: shard, realm: realm)

        XCTAssertEqual(client.getShard(), shard)
        XCTAssertEqual(client.getRealm(), realm)
    }
}
