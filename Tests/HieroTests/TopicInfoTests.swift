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

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TopicInfoTests: XCTestCase {
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
            proto.adminKey = Resources.publicKey.toProtobuf()
            proto.submitKey = Resources.publicKey.toProtobuf()
            proto.autoRenewPeriod = Duration.days(5).toProtobuf()
            proto.autoRenewAccount = AccountId(num: 4).toProtobuf()
            proto.ledgerID = LedgerId.testnet.bytes
            proto.feeScheduleKey = feeScheduleKey.toProtobuf()
            proto.feeExemptKeyList = feeExemptKeys.map { $0.toProtobuf() }
            proto.customFees = customFees.map { $0.toProtobuf() }
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
