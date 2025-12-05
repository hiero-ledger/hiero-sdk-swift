// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenAllowanceUnitTests: HieroUnitTestCase {

    private static let testSpenderAccountId = AccountId("0.2.24")

    private static func makeAllowance() -> TokenAllowance {
        TokenAllowance(
            tokenId: TestConstants.tokenId, ownerAccountId: TestConstants.accountId, spenderAccountId: testSpenderAccountId,
            amount: 4)
    }

    internal func test_Serialize() throws {
        let allowance = Self.makeAllowance()

        SnapshotTesting.assertSnapshot(of: allowance, as: .description)
    }

    internal func test_FromProtobuf() throws {
        let allowanceProto = Self.makeAllowance().toProtobuf()
        let allowance = try TokenAllowance.fromProtobuf(allowanceProto)

        SnapshotTesting.assertSnapshot(of: allowance, as: .description)
    }

    internal func test_ToProtobuf() throws {
        let allowanceProto = Self.makeAllowance().toProtobuf()

        SnapshotTesting.assertSnapshot(of: allowanceProto, as: .description)
    }
}
