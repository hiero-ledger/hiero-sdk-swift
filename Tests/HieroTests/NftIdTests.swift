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

import SnapshotTesting
import XCTest

@testable import Hiero

private let parsedNftId = NftId(tokenId: TokenId(shard: 1415, realm: 314, num: 123), serial: 456)

internal final class NftIdTests: XCTestCase {
    internal func testParseSlashFormat() {

        let actualNftId: NftId = "1415.314.123/456"

        XCTAssertEqual(parsedNftId, actualNftId)
    }

    internal func testParseAtFormat() {
        let actualNftId: NftId = "1415.314.123@456"

        XCTAssertEqual(parsedNftId, actualNftId)
    }

    internal func testFromString() throws {
        assertSnapshot(matching: try NftId.fromString("0.0.5005@1234"), as: .description)
    }

    internal func testFromString2() throws {
        assertSnapshot(matching: try NftId.fromString("0.0.5005/1234"), as: .description)
    }

    internal func testfromStringWithChecksumOnMainnet() throws {
        let nftId = try NftId.fromString("0.0.123-vfmkw/7584")
        try nftId.validateChecksums(on: .mainnet)
    }

    internal func testfromStringWithChecksumOnTestnet() throws {
        let nftId = try NftId.fromString("0.0.123-esxsf@584903")
        try nftId.validateChecksums(on: .testnet)
    }

    internal func testfromStringWithChecksumOnPreviewnet() throws {
        let nftId = try NftId.fromString("0.0.123-ogizo/487302")
        try nftId.validateChecksums(on: .previewnet)
    }

    internal func testFromBytes() throws {
        let nftId = TokenId(5005).nft(574489).toBytes()

        assertSnapshot(matching: try NftId.fromBytes(nftId), as: .description)
    }

    internal func testToBytes() throws {
        let nftId = TokenId(5005).nft(4920)

        assertSnapshot(matching: nftId.toBytes().hexStringEncoded(), as: .description)
    }
}
