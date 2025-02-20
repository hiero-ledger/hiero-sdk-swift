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

internal final class AssessedCustomFeeTests: XCTestCase {
    private static let amount: Int64 = 1
    private static let tokenId: TokenId = "2.3.4"
    private static let feeCollector: AccountId = "5.6.7"

    private static let payerAccountIds: [AccountId] = [
        "8.9.10",
        "11.12.13",
        "14.15.16",
    ]

    private static let feeProto: Proto_AssessedCustomFee = .with { proto in
        proto.amount = amount
        proto.tokenID = tokenId.toProtobuf()
        proto.feeCollectorAccountID = feeCollector.toProtobuf()
        proto.effectivePayerAccountID = payerAccountIds.toProtobuf()
    }

    private static let fee: AssessedCustomFee = AssessedCustomFee(
        amount: 201,
        tokenId: "1.2.3",
        feeCollectorAccountId: "4.5.6",
        payerAccountIdList: [1, 2, 3]
    )

    internal func testSerialize() throws {
        let original = Self.fee
        let bytes = original.toBytes()
        let new = try AssessedCustomFee.fromBytes(bytes)

        XCTAssertEqual(original, new)

        assertSnapshot(matching: original, as: .description)
    }

    internal func testFromProtobuf() {
        assertSnapshot(matching: try AssessedCustomFee.fromProtobuf(Self.feeProto), as: .description)
    }

    internal func testToProtobuf() {
        assertSnapshot(matching: try AssessedCustomFee.fromProtobuf(Self.feeProto).toProtobuf(), as: .description)
    }

    internal func testToBytes() {
        XCTAssertEqual(Self.fee, try AssessedCustomFee.fromBytes(Self.fee.toBytes()))
    }
}
