// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class FeeSchedulesUnitTests: HieroUnitTestCase {
    private static func makeFeeComponent(_ min: UInt64, _ max: UInt64) -> FeeComponents {
        FeeComponents(
            min: min, max: max, constant: 0, bandwidthByte: 0, verification: 0, storageByteHour: 0, ramByteHour: 0,
            contractTransactionGas: 0, transferVolumeHbar: 0, responseMemoryByte: 0, responseDiskByte: 0)
    }

    private let feeSchedules: FeeSchedules = FeeSchedules(
        current: FeeSchedule.init(
            transactionFeeSchedules: [
                TransactionFeeSchedule(
                    requestType: nil,
                    fees: [
                        FeeData.init(
                            node: makeFeeComponent(0, 0), network: makeFeeComponent(2, 5),
                            service: makeFeeComponent(0, 0), kind: FeeDataType.default)
                    ])
            ], expirationTime: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0)),
        next: FeeSchedule.init(
            transactionFeeSchedules: [
                TransactionFeeSchedule(
                    requestType: nil,
                    fees: [
                        FeeData.init(
                            node: makeFeeComponent(1, 2), network: makeFeeComponent(0, 0),
                            service: makeFeeComponent(0, 0), kind: FeeDataType.default)
                    ])
            ], expirationTime: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0))
    )

    internal func test_Serialize() throws {
        SnapshotTesting.assertSnapshot(of: feeSchedules, as: .description)
    }

    internal func test_ToFromBytes() throws {
        SnapshotTesting.assertSnapshot(of: try FeeSchedules.fromBytes(feeSchedules.toBytes()), as: .description)
    }

    internal func test_SerializeDefault() throws {
        let schedules = FeeSchedules(current: nil, next: nil)

        SnapshotTesting.assertSnapshot(of: schedules, as: .description)
    }

    internal func test_ToFromBytesDefault() throws {
        let schedules = FeeSchedules(current: nil, next: nil)

        let bytesSchedule = try FeeSchedules.fromBytes(schedules.toBytes())

        SnapshotTesting.assertSnapshot(of: bytesSchedule, as: .description)

    }
}
