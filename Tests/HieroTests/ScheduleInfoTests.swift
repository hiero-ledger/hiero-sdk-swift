// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

import struct HieroProtobufs.Proto_CryptoDeleteTransactionBody
import struct HieroProtobufs.Proto_ScheduleInfo
import struct HieroProtobufs.Proto_Timestamp

@testable import Hiero

internal final class ScheduleInfoTests: XCTestCase {
    private func makeDeleteInfo() throws -> ScheduleInfo {
        let scheduleId = AnySchedulableTransaction.accountDelete(
            AccountDeleteTransaction.init().accountId(AccountId("6.6.6"))
        ).toSchedulableTransactionData()

        let info = try ScheduleInfo.init(
            protobuf: try .with { proto in
                proto.scheduleID = try ScheduleId.fromString("1.2.3").toProtobuf()
                proto.payerAccountID = try AccountId.fromString("3.4.5").toProtobuf()
                proto.creatorAccountID = try AccountId.fromString("6.7.8").toProtobuf()
                proto.scheduledTransactionID = .with { proto in
                    proto.accountID = .with { proto in
                        proto.accountNum = 5006
                    }
                    proto.nonce = 0
                    proto.scheduled = false
                }
                proto.scheduledTransactionBody = .with { proto in
                    proto.data = scheduleId
                    proto.memo = ""
                    proto.transactionFee = 200_000_000
                }
                proto.signers = .with { proto in
                    proto.keys = [Resources.publicKey.toProtobuf()]
                }
                proto.waitForExpiry = true
                proto.adminKey = Resources.publicKey.toProtobuf()
                proto.memo = "flook"
                proto.ledgerID = LedgerId.testnet.bytes
                proto.deletionTime = Timestamp(seconds: 1_554_158_542, subSecondNanos: 0).toProtobuf()
            })

        return info
    }

    private func makeInfo() throws -> ScheduleInfo {
        let scheduleId = AnySchedulableTransaction.accountDelete(
            AccountDeleteTransaction.init().accountId(AccountId("6.6.6"))
        ).toSchedulableTransactionData()

        let info = try ScheduleInfo.init(
            protobuf: try .with { proto in
                proto.scheduleID = try ScheduleId.fromString("1.2.3").toProtobuf()
                proto.payerAccountID = try AccountId.fromString("3.4.5").toProtobuf()
                proto.creatorAccountID = try AccountId.fromString("6.7.8").toProtobuf()
                proto.scheduledTransactionID = .with { proto in
                    proto.accountID = .with { proto in
                        proto.accountNum = 5006
                    }
                    proto.nonce = 0
                    proto.scheduled = false
                }
                proto.scheduledTransactionBody = .with { proto in
                    proto.data = scheduleId
                    proto.memo = ""
                    proto.transactionFee = 200_000_000
                }
                proto.signers = .with { proto in
                    proto.keys = [Resources.publicKey.toProtobuf()]
                }
                proto.waitForExpiry = true
                proto.adminKey = Resources.publicKey.toProtobuf()
                proto.memo = "flook"
                proto.ledgerID = LedgerId.testnet.bytes
                proto.executionTime = Timestamp(seconds: 1_554_158_542, subSecondNanos: 0).toProtobuf()
            })

        return info
    }

    internal func testSerialize() throws {
        let info = try makeInfo()

        assertSnapshot(of: info, as: .description)
    }

    internal func testSerializeDeleted() throws {
        let info = try makeDeleteInfo()

        assertSnapshot(of: info, as: .description)
    }
}
