// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ProxyStakerTests: XCTestCase {
    private static let proxyStaker: Proto_ProxyStaker = .with { proto in
        proto.accountID = Resources.accountId.toProtobuf()
        proto.amount = 10
    }

    internal func testFromProtobuf() throws {
        assertSnapshot(matching: try ProxyStaker.fromProtobuf(Self.proxyStaker), as: .description)
    }

    internal func testToProtobuf() throws {
        assertSnapshot(matching: try ProxyStaker.fromProtobuf(Self.proxyStaker).toProtobuf(), as: .description)
    }
}
