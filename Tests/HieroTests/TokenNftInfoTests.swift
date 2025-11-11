// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenNftInfoTests: XCTestCase {
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

    internal func testSerialize() throws {
        let info = try TokenNftInfo.fromBytes(Self.makeInfo(spenderAccountId: "8.9.10").toBytes())

        assertSnapshot(of: info, as: .description)
    }

    internal func testSerializeNoSpender() throws {
        let info = try TokenNftInfo.fromBytes(Self.makeInfo(spenderAccountId: nil).toBytes())

        assertSnapshot(of: info, as: .description)
    }
}
