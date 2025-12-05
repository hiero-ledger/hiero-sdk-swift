// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal class TokenNftTransferUnitTests: HieroUnitTestCase {
    internal static let testReceiver = AccountId("0.0.5008")
    internal static let testSerialNumber = 4

    private func makeTransfer() throws -> TokenNftTransfer {
        TokenNftTransfer.init(
            tokenId: TestConstants.tokenId, sender: TestConstants.accountId, receiver: Self.testReceiver, serial: 4,
            isApproved: true)
    }

    internal func test_Serialize() throws {
        let transfer = try makeTransfer()

        SnapshotTesting.assertSnapshot(of: transfer, as: .description)
    }
}
