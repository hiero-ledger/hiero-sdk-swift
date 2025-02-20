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

        assertSnapshot(matching: info, as: .description)
    }

    internal func testSerializeNoSpender() throws {
        let info = try TokenNftInfo.fromBytes(Self.makeInfo(spenderAccountId: nil).toBytes())

        assertSnapshot(matching: info, as: .description)
    }
}
