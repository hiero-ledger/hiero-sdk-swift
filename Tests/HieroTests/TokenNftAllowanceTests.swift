// SPDX-License-Identifier: Apache-2.0

import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenNftAllowanceTests: XCTestCase {
    private func makeAllowance() throws -> TokenNftAllowance {
        TokenNftAllowance.init(
            tokenId: try TokenId.fromString("1.2.3"),
            ownerAccountId: AccountId(num: 5006),
            spenderAccountId: AccountId(num: 5007),
            serials: [1, 2],
            approvedForAll: true,
            delegatingSpenderAccountId: AccountId(num: 5008)
        )
    }

    internal func testSerialize() throws {
        let allowance = try makeAllowance()

        assertSnapshot(of: allowance, as: .description)
    }
}
