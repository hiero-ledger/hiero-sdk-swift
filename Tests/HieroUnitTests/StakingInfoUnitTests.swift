// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class StakingInfoUnitTests: HieroUnitTestCase {
    private static let stakingInfoAccount: Proto_StakingInfo = .with { proto in
        proto.declineReward = true
        proto.stakePeriodStart = TestConstants.validStart.toProtobuf()
        proto.pendingReward = 5
        proto.stakedToMe = 10
        proto.stakedAccountID = TestConstants.accountId.toProtobuf()
    }

    private static let stakingInfoNode: Proto_StakingInfo = .with { proto in
        proto.declineReward = true
        proto.stakePeriodStart = TestConstants.validStart.toProtobuf()
        proto.pendingReward = 5
        proto.stakedToMe = 10
        proto.stakedNodeID = 3
    }

    internal func test_FromProtobufAccount() throws {
        SnapshotTesting.assertSnapshot(of: try StakingInfo.fromProtobuf(Self.stakingInfoAccount), as: .description)
    }

    internal func test_ToProtobufAccount() throws {
        SnapshotTesting.assertSnapshot(of: try StakingInfo.fromProtobuf(Self.stakingInfoAccount).toProtobuf(), as: .description)
    }

    internal func test_FromProtobufNode() throws {
        SnapshotTesting.assertSnapshot(of: try StakingInfo.fromProtobuf(Self.stakingInfoNode), as: .description)
    }

    internal func test_ToProtobufNode() throws {
        SnapshotTesting.assertSnapshot(of: try StakingInfo.fromProtobuf(Self.stakingInfoNode).toProtobuf(), as: .description)
    }

    internal func test_FromBytesAccount() throws {
        SnapshotTesting.assertSnapshot(of: try StakingInfo.fromBytes(Self.stakingInfoAccount.serializedData()), as: .description)
    }

    internal func test_ToBytesAccount() throws {
        SnapshotTesting.assertSnapshot(
            of: try StakingInfo.fromBytes(Self.stakingInfoAccount.serializedData()).toBytes().hexStringEncoded(),
            as: .description)
    }

    internal func test_FromBytesNode() throws {
        SnapshotTesting.assertSnapshot(of: try StakingInfo.fromBytes(Self.stakingInfoNode.serializedData()), as: .description)
    }

    internal func test_ToBytesNode() throws {
        SnapshotTesting.assertSnapshot(
            of: try StakingInfo.fromBytes(Self.stakingInfoNode.serializedData()).toBytes().hexStringEncoded(),
            as: .description)
    }
}
