// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TransactionFeeScheduleTests: XCTestCase {
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

    internal func testSerialize() throws {
        let schedule = try Self.makeSchedule()
        assertSnapshot(of: schedule, as: .description)
    }

    internal func testToProtobuf() throws {
        let scheduleProto = try Self.makeSchedule().toProtobuf()

        assertSnapshot(of: scheduleProto, as: .description)
    }

    internal func testFromProtobuf() throws {
        let scheduleProto = try Self.makeSchedule().toProtobuf()
        let schedule = try TransactionFeeSchedule.fromProtobuf(scheduleProto)

        assertSnapshot(of: schedule, as: .description)
    }

    internal func testFromBytes() throws {
        let schedule = try TransactionFeeSchedule.fromBytes(try Self.makeSchedule().toBytes())

        assertSnapshot(of: schedule, as: .description)
    }

    internal func testToBytes() throws {
        let schedule = try Self.makeSchedule().toBytes().hexStringEncoded()

        assertSnapshot(of: schedule, as: .description)
    }
}
