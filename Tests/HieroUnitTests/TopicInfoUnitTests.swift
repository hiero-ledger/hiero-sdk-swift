// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicInfoUnitTests: HieroUnitTestCase {
    private static let feeExemptKeys: [Key] = [
        .single(
            try! PrivateKey.fromString(
                "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e10"
            ).publicKey),
        .single(
            try! PrivateKey.fromString(
                "302e020100300506032b657004220420aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899"
            ).publicKey),
    ]

    private static let feeScheduleKey: Key = .single(
        try! PrivateKey.fromString(
            "302e020100300506032b657004220420aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899"
        ).publicKey)

    private static let customFees = [
        CustomFixedFee(
            100, nil, TokenId(shard: 4, realm: 1, num: 1))
    ]

    private static let topicInfo: Proto_ConsensusGetTopicInfoResponse = .with { proto in
        proto.topicID = TopicId(shard: 0, realm: 6, num: 9).toProtobuf()
        proto.topicInfo = .with { proto in
            proto.memo = "1"
            proto.runningHash = Data([2])
            proto.sequenceNumber = 3
            proto.expirationTime = Timestamp(seconds: 0, subSecondNanos: 4_000_000).toProtobuf()
            proto.adminKey = TestConstants.publicKey.toProtobuf()
            proto.submitKey = TestConstants.publicKey.toProtobuf()
            proto.autoRenewPeriod = Duration.days(5).toProtobuf()
            proto.autoRenewAccount = AccountId(num: 4).toProtobuf()
            proto.ledgerID = LedgerId.testnet.bytes
            proto.feeScheduleKey = feeScheduleKey.toProtobuf()
            proto.feeExemptKeyList = feeExemptKeys.map { $0.toProtobuf() }
            proto.customFees = customFees.map { $0.toProtobuf() }
        }
    }

    internal func test_FromBytes() throws {
        let info = try TopicInfo.fromBytes(Self.topicInfo.serializedData())

        SnapshotTesting.assertSnapshot(of: info, as: .description)
    }

    internal func test_FromProtobuf() throws {
        let pb = Self.topicInfo
        let info = try TopicInfo.fromProtobuf(pb)

        SnapshotTesting.assertSnapshot(of: info, as: .description)
    }

    internal func test_ToProtobuf() throws {
        let info = try TopicInfo.fromProtobuf(Self.topicInfo).toProtobuf()
        SnapshotTesting.assertSnapshot(of: info, as: .description)
    }
}
