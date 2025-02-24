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
        assertSnapshot(matching: schedule, as: .description)
    }

    internal func testToProtobuf() throws {
        let scheduleProto = try Self.makeSchedule().toProtobuf()

        assertSnapshot(matching: scheduleProto, as: .description)
    }

    internal func testFromProtobuf() throws {
        let scheduleProto = try Self.makeSchedule().toProtobuf()
        let schedule = try TransactionFeeSchedule.fromProtobuf(scheduleProto)

        assertSnapshot(matching: schedule, as: .description)
    }

    internal func testFromBytes() throws {
        let schedule = try TransactionFeeSchedule.fromBytes(try Self.makeSchedule().toBytes())

        assertSnapshot(matching: schedule, as: .description)
    }

    internal func testToBytes() throws {
        let schedule = try Self.makeSchedule().toBytes().hexStringEncoded()

        assertSnapshot(matching: schedule, as: .description)
    }
}
