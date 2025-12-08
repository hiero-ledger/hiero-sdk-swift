// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class CustomFeeUnitTests: HieroUnitTestCase {
    private static let customFixedFee = Proto_CustomFee.with { proto in
        proto.feeCollectorAccountID = AccountId(4322).toProtobuf()
        proto.fee = .fixedFee(
            Proto_FixedFee.with { proto in
                proto.amount = 10
                proto.denominatingTokenID = TokenId(483902).toProtobuf()
            })
    }

    private static let customFractionalFee = Proto_CustomFee.with { proto in
        proto.feeCollectorAccountID = AccountId(389042).toProtobuf()
        proto.fee = .fractionalFee(
            Proto_FractionalFee.with { proto in
                proto.fractionalAmount = .with { proto in
                    proto.numerator = 3
                    proto.denominator = 7
                }
                proto.minimumAmount = 3
                proto.maximumAmount = 100
            })
    }

    private static let customRoyaltyFee = Proto_CustomFee.with { proto in
        proto.feeCollectorAccountID = AccountId(23423).toProtobuf()
        proto.fee = .royaltyFee(
            Proto_RoyaltyFee.with { proto in
                proto.fallbackFee = .with { proto in
                    proto.amount = 10
                    proto.denominatingTokenID = TokenId(483902).toProtobuf()
                }
                proto.exchangeValueFraction = .with { proto in
                    proto.numerator = 5
                    proto.denominator = 8
                }
            })
    }

    internal func test_SerializeFixed() throws {
        SnapshotTesting.assertSnapshot(of: Self.customFixedFee, as: .description)
    }

    internal func test_SerializeFractional() throws {
        SnapshotTesting.assertSnapshot(of: Self.customFractionalFee, as: .description)
    }

    internal func test_SerializeRoyalty() throws {
        SnapshotTesting.assertSnapshot(of: Self.customRoyaltyFee, as: .description)
    }

    internal func test_FixedFromToBytes() throws {
        let fixed = try AnyCustomFee.fromProtobuf(Self.customFixedFee)
        let bytes = fixed.toBytes()
        XCTAssertEqual(try AnyCustomFee.fromBytes(bytes), fixed)
    }

    internal func test_FractionalFromToBytes() throws {
        let fractional = try AnyCustomFee.fromProtobuf(Self.customFractionalFee)
        let bytes = fractional.toBytes()
        XCTAssertEqual(try AnyCustomFee.fromBytes(bytes), fractional)
    }

    internal func test_RoyaltyFromToBytes() throws {
        let royalty = try AnyCustomFee.fromProtobuf(Self.customRoyaltyFee)
        let bytes = royalty.toBytes()
        XCTAssertEqual(try AnyCustomFee.fromBytes(bytes), royalty)
    }

    internal func test_FixedFromProtobuf() throws {
        SnapshotTesting.assertSnapshot(of: try AnyCustomFee.fromProtobuf(Self.customFixedFee), as: .description)
    }

    internal func test_FractionalFromProtobuf() throws {
        SnapshotTesting.assertSnapshot(of: try AnyCustomFee.fromProtobuf(Self.customFractionalFee), as: .description)
    }

    internal func test_RoyaltyFromProtobuf() throws {
        SnapshotTesting.assertSnapshot(of: try AnyCustomFee.fromProtobuf(Self.customRoyaltyFee), as: .description)
    }
}
