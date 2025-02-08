// SPDX-License-Identifier: Apache-2.0

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
