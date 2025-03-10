/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
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

internal final class CustomFeeLimitTests: XCTestCase {
    private static let testPayerId = AccountId(num: 1234)

    private static let testFixedFeeProto = Proto_FixedFee.with { proto in
        proto.amount = 1000
    }

    private static let testCustomFixedFee = CustomFixedFee(
        UInt64(testFixedFeeProto.amount),
        nil,
        nil
    )

    private static let testFees = [testCustomFixedFee]

    private static let testCustomFeeLimit = CustomFeeLimit(
        payerId: testPayerId,
        customFees: testFees
    )

    internal func testSerialize() throws {
        let proto = Self.testCustomFeeLimit.toProtobuf()
        assertSnapshot(matching: proto, as: .description)
    }

    internal func testGetSetPayerId() {
        let newPayerId = AccountId(num: 5678)
        var feeLimit = Self.testCustomFeeLimit

        XCTAssertEqual(Self.testPayerId, feeLimit.payerId)
        feeLimit.payerId = newPayerId
        XCTAssertEqual(newPayerId, feeLimit.payerId)
    }

    internal func testGetSetCustomFees() {
        let newFees: [CustomFixedFee] = []
        var feeLimit = Self.testCustomFeeLimit

        XCTAssertEqual(Self.testFees, feeLimit.customFees)
        feeLimit.customFees = newFees
        XCTAssertEqual(newFees, feeLimit.customFees)
    }

    internal func testToProtobuf() {
        let proto = Self.testCustomFeeLimit.toProtobuf()

        XCTAssertEqual(Self.testPayerId.toProtobuf(), proto.accountID)
        XCTAssertFalse(proto.fees.isEmpty)
    }

    internal func testFromProtobuf() throws {
        let proto = Proto_CustomFeeLimit.with { proto in
            proto.accountID = Self.testPayerId.toProtobuf()
            proto.fees = Self.testFees.map { fee in
                CustomFixedFee(
                    fee.amount,
                    fee.feeCollectorAccountId,
                    fee.denominatingTokenId
                ).toProtobuf().fixedFee
            }
        }

        let converted = try CustomFeeLimit(protobuf: proto)

        XCTAssertEqual(Self.testPayerId, converted.payerId)
        XCTAssertEqual(Self.testCustomFixedFee.feeCollectorAccountId, converted.customFees[0].feeCollectorAccountId)
    }

}
