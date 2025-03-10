// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenAllowanceTests: XCTestCase {

    private static let testSpenderAccountId = AccountId("0.2.24")

    private static func makeAllowance() -> TokenAllowance {
        TokenAllowance(
            tokenId: Resources.tokenId, ownerAccountId: Resources.accountId, spenderAccountId: testSpenderAccountId,
            amount: 4)
    }

    internal func testSerialize() throws {
        let allowance = Self.makeAllowance()

        assertSnapshot(matching: allowance, as: .description)
    }

    internal func testFromProtobuf() throws {
        let allowanceProto = Self.makeAllowance().toProtobuf()
        let allowance = try TokenAllowance.fromProtobuf(allowanceProto)

        assertSnapshot(matching: allowance, as: .description)
    }

    internal func testToProtobuf() throws {
        let allowanceProto = Self.makeAllowance().toProtobuf()

        assertSnapshot(matching: allowanceProto, as: .description)
    }
}
