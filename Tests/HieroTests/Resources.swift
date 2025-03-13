// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal enum Resources {
    internal static let nodeAccountIds: [AccountId] = [5005, 5006]
    internal static let validStart = Timestamp(seconds: 1_554_158_542, subSecondNanos: 0)
    internal static let txId = TransactionId(accountId: 5006, validStart: validStart)
    internal static let scheduleId = ScheduleId("0.0.555")
    internal static let accountId = AccountId("0.0.5009")
    internal static let fileId = FileId("1.2.3")
    internal static let tokenId = TokenId("0.3.5")
    internal static let topicId = TopicId("4.4.4")
    internal static let metadata = Data([3, 4])

    // some unused private key
    internal static let privateKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e10"

    internal static var publicKey: PublicKey {
        privateKey.publicKey
    }

    internal static func checkTransactionBody(body: Proto_TransactionBody) throws -> Proto_TransactionBody.OneOf_Data {
        let txBody = body

        let nodeAccountId = txBody.nodeAccountID

        XCTAssertEqual(txBody.transactionID, Self.txId.toProtobuf())

        XCTAssert(Resources.nodeAccountIds.contains(try AccountId.fromProtobuf(nodeAccountId)))

        XCTAssertEqual(txBody.transactionFee, UInt64(Hbar(2).toTinybars()))

        XCTAssertEqual(txBody.transactionValidDuration, Duration.seconds(120).toProtobuf())
        XCTAssertEqual(txBody.generateRecord, false)
        XCTAssertEqual(txBody.memo, "")

        return txBody.data!
    }

}
