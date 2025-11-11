// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

@testable import Hiero

internal final class FeeScheduleTests: XCTestCase {
    private static func makeFeeComponent(_ min: UInt64, _ max: UInt64) -> FeeComponents {
        FeeComponents(
            min: min, max: max, constant: 0, bandwidthByte: 0, verification: 0, storageByteHour: 0, ramByteHour: 0,
            contractTransactionGas: 0, transferVolumeHbar: 0, responseMemoryByte: 0, responseDiskByte: 0)
    }

    private let feeSchedule: FeeSchedule =
        FeeSchedule.init(
            transactionFeeSchedules: [
                TransactionFeeSchedule(
                    requestType: nil,
                    fees: [
                        FeeData.init(
                            node: makeFeeComponent(0, 0), network: makeFeeComponent(2, 5),
                            service: makeFeeComponent(0, 0), kind: FeeDataType.default)
                    ])
            ], expirationTime: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0))

    internal func testSerialize() throws {
        assertSnapshot(of: feeSchedule, as: .description)
    }

    internal func testToFromBytes() throws {
        assertSnapshot(of: try FeeSchedule.fromBytes(feeSchedule.toBytes()), as: .description)
    }

    internal func testFromProtobuf() throws {
        let feeSchedule = try FeeSchedule.fromProtobuf(feeSchedule.toProtobuf())

        assertSnapshot(of: feeSchedule, as: .description)
    }

    internal func testToProtobuf() throws {
        let protoFeeSchedule = feeSchedule.toProtobuf()

        assertSnapshot(of: protoFeeSchedule, as: .description)
    }
}
