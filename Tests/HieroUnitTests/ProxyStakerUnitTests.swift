// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class ProxyStakerUnitTests: HieroUnitTestCase {
    private static let proxyStaker: Proto_ProxyStaker = .with { proto in
        proto.accountID = TestConstants.accountId.toProtobuf()
        proto.amount = 10
    }

    internal func test_FromProtobuf() throws {
        SnapshotTesting.assertSnapshot(of: try ProxyStaker.fromProtobuf(Self.proxyStaker), as: .description)
    }

    internal func test_ToProtobuf() throws {
        SnapshotTesting.assertSnapshot(of: try ProxyStaker.fromProtobuf(Self.proxyStaker).toProtobuf(), as: .description)
    }
}
