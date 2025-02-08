// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicInfoTests: XCTestCase {
    private static let topicInfo: Proto_ConsensusGetTopicInfoResponse = .with { proto in
        proto.topicID = TopicId(shard: 0, realm: 6, num: 9).toProtobuf()
        proto.topicInfo = .with { proto in
            proto.memo = "1"
            proto.runningHash = Data([2])
            proto.sequenceNumber = 3
            proto.expirationTime = Timestamp(seconds: 0, subSecondNanos: 4_000_000).toProtobuf()
            proto.adminKey = Resources.publicKey.toProtobuf()
            proto.submitKey = Resources.publicKey.toProtobuf()
            proto.autoRenewPeriod = Duration.days(5).toProtobuf()
            proto.autoRenewAccount = AccountId(num: 4).toProtobuf()
            proto.ledgerID = LedgerId.testnet.bytes
        }
    }

    internal func testFromBytes() throws {
        let info = try TopicInfo.fromBytes(Self.topicInfo.serializedData())

        assertSnapshot(matching: info, as: .description)
    }

    internal func testFromProtobuf() throws {
        let pb = Self.topicInfo
        let info = try TopicInfo.fromProtobuf(pb)

        assertSnapshot(matching: info, as: .description)
    }

    internal func testToProtobuf() throws {
        let info = try TopicInfo.fromProtobuf(Self.topicInfo).toProtobuf()
        assertSnapshot(matching: info, as: .description)
    }
}
