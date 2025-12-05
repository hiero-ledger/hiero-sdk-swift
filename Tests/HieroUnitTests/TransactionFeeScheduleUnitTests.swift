// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TransactionFeeScheduleUnitTests: HieroUnitTestCase {
    private static func makeFeeComponent(_ min: UInt64, _ max: UInt64) -> FeeComponents {
        FeeComponents(
            min: min, max: max, constant: 2, bandwidthByte: 5, verification: 6, storageByteHour: 0, ramByteHour: 0,
            contractTransactionGas: 3, transferVolumeHbar: 2, responseMemoryByte: 7, responseDiskByte: 0)
    }
    private static func makeSchedule() throws -> TransactionFeeSchedule {
        TransactionFeeSchedule(
            requestType: nil,
            fees: [
                FeeData(
                    node: makeFeeComponent(4, 7), network: makeFeeComponent(2, 5),
                    service: makeFeeComponent(4, 6), kind: FeeDataType.default)
            ])
    }

    internal func test_Serialize() throws {
        let schedule = try Self.makeSchedule()
        SnapshotTesting.assertSnapshot(of: schedule, as: .description)
    }

    internal func test_ToProtobuf() throws {
        let scheduleProto = try Self.makeSchedule().toProtobuf()

        SnapshotTesting.assertSnapshot(of: scheduleProto, as: .description)
    }

    internal func test_FromProtobuf() throws {
        let scheduleProto = try Self.makeSchedule().toProtobuf()
        let schedule = try TransactionFeeSchedule.fromProtobuf(scheduleProto)

        SnapshotTesting.assertSnapshot(of: schedule, as: .description)
    }

    internal func test_FromBytes() throws {
        let schedule = try TransactionFeeSchedule.fromBytes(try Self.makeSchedule().toBytes())

        SnapshotTesting.assertSnapshot(of: schedule, as: .description)
    }

    internal func test_ToBytes() throws {
        let schedule = try Self.makeSchedule().toBytes().hexStringEncoded()

        SnapshotTesting.assertSnapshot(of: schedule, as: .description)
    }
}
