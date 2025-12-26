// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

private let parsedNftId = NftId(tokenId: TokenId(shard: 1415, realm: 314, num: 123), serial: 456)

internal final class NftIdUnitTests: HieroUnitTestCase {
    internal func test_ParseSlashFormat() {

        let actualNftId: NftId = "1415.314.123/456"

        XCTAssertEqual(parsedNftId, actualNftId)
    }

    internal func test_ParseAtFormat() {
        let actualNftId: NftId = "1415.314.123@456"

        XCTAssertEqual(parsedNftId, actualNftId)
    }

    internal func test_FromString() throws {
        SnapshotTesting.assertSnapshot(of: try NftId.fromString("0.0.5005@1234"), as: .description)
    }

    internal func test_FromString2() throws {
        SnapshotTesting.assertSnapshot(of: try NftId.fromString("0.0.5005/1234"), as: .description)
    }

    internal func test_fromStringWithChecksumOnMainnet() throws {
        let nftId = try NftId.fromString("0.0.123-vfmkw/7584")
        try nftId.validateChecksums(on: .mainnet)
    }

    internal func test_fromStringWithChecksumOnTestnet() throws {
        let nftId = try NftId.fromString("0.0.123-esxsf@584903")
        try nftId.validateChecksums(on: .testnet)
    }

    internal func test_fromStringWithChecksumOnPreviewnet() throws {
        let nftId = try NftId.fromString("0.0.123-ogizo/487302")
        try nftId.validateChecksums(on: .previewnet)
    }

    internal func test_FromBytes() throws {
        let nftId = TokenId(5005).nft(574489).toBytes()

        SnapshotTesting.assertSnapshot(of: try NftId.fromBytes(nftId), as: .description)
    }

    internal func test_ToBytes() throws {
        let nftId = TokenId(5005).nft(4920)

        SnapshotTesting.assertSnapshot(of: nftId.toBytes().hexStringEncoded(), as: .description)
    }
}
