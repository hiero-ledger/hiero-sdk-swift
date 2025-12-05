// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class AssessedCustomFeeUnitTests: HieroUnitTestCase {
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

    internal func test_Serialize() throws {
        let original = Self.fee
        let bytes = original.toBytes()
        let new = try AssessedCustomFee.fromBytes(bytes)

        XCTAssertEqual(original, new)

        SnapshotTesting.assertSnapshot(of: original, as: .description)
    }

    internal func test_FromProtobuf() {
        SnapshotTesting.assertSnapshot(of: try AssessedCustomFee.fromProtobuf(Self.feeProto), as: .description)
    }

    internal func test_ToProtobuf() {
        SnapshotTesting.assertSnapshot(of: try AssessedCustomFee.fromProtobuf(Self.feeProto).toProtobuf(), as: .description)
    }

    internal func test_ToBytes() {
        XCTAssertEqual(Self.fee, try AssessedCustomFee.fromBytes(Self.fee.toBytes()))
    }
}
