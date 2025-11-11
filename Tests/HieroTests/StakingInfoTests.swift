// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class StakingInfoTests: XCTestCase {
    private static let stakingInfoAccount: Proto_StakingInfo = .with { proto in
        proto.declineReward = true
        proto.stakePeriodStart = Resources.validStart.toProtobuf()
        proto.pendingReward = 5
        proto.stakedToMe = 10
        proto.stakedAccountID = Resources.accountId.toProtobuf()
    }

    private static let stakingInfoNode: Proto_StakingInfo = .with { proto in
        proto.declineReward = true
        proto.stakePeriodStart = Resources.validStart.toProtobuf()
        proto.pendingReward = 5
        proto.stakedToMe = 10
        proto.stakedNodeID = 3
    }

    internal func testFromProtobufAccount() throws {
        assertSnapshot(of: try StakingInfo.fromProtobuf(Self.stakingInfoAccount), as: .description)
    }

    internal func testToProtobufAccount() throws {
        assertSnapshot(of: try StakingInfo.fromProtobuf(Self.stakingInfoAccount).toProtobuf(), as: .description)
    }

    internal func testFromProtobufNode() throws {
        assertSnapshot(of: try StakingInfo.fromProtobuf(Self.stakingInfoNode), as: .description)
    }

    internal func testToProtobufNode() throws {
        assertSnapshot(of: try StakingInfo.fromProtobuf(Self.stakingInfoNode).toProtobuf(), as: .description)
    }

    internal func testFromBytesAccount() throws {
        assertSnapshot(of: try StakingInfo.fromBytes(Self.stakingInfoAccount.serializedData()), as: .description)
    }

    internal func testToBytesAccount() throws {
        assertSnapshot(
            of: try StakingInfo.fromBytes(Self.stakingInfoAccount.serializedData()).toBytes().hexStringEncoded(),
            as: .description)
    }

    internal func testFromBytesNode() throws {
        assertSnapshot(of: try StakingInfo.fromBytes(Self.stakingInfoNode.serializedData()), as: .description)
    }

    internal func testToBytesNode() throws {
        assertSnapshot(
            of: try StakingInfo.fromBytes(Self.stakingInfoNode.serializedData()).toBytes().hexStringEncoded(),
            as: .description)
    }
}
