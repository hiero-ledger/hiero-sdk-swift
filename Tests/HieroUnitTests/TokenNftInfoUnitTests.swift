// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenNftInfoUnitTests: HieroUnitTestCase {
    private static func makeInfo(spenderAccountId: AccountId?) -> TokenNftInfo {
        TokenNftInfo(
            nftId: "1.2.3/4",
            accountId: "5.6.7",
            creationTime: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0),
            metadata: Data([0xde, 0xad, 0xbe, 0xef]),
            spenderId: spenderAccountId,
            ledgerId: .mainnet
        )
    }

    internal func test_Serialize() throws {
        let info = try TokenNftInfo.fromBytes(Self.makeInfo(spenderAccountId: "8.9.10").toBytes())

        SnapshotTesting.assertSnapshot(of: info, as: .description)
    }

    internal func test_SerializeNoSpender() throws {
        let info = try TokenNftInfo.fromBytes(Self.makeInfo(spenderAccountId: nil).toBytes())

        SnapshotTesting.assertSnapshot(of: info, as: .description)
    }
}
