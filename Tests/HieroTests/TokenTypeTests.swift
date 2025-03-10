// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenTypeTests: XCTestCase {
    internal func testToProtobuf() throws {
        let fungibleTokenProto = TokenType.fungibleCommon.toProtobuf()
        let nftTokenProto = TokenType.nonFungibleUnique.toProtobuf()

        XCTAssertEqual(fungibleTokenProto, Proto_TokenType.fungibleCommon)
        XCTAssertEqual(nftTokenProto, Proto_TokenType.nonFungibleUnique)
    }

    internal func testFromProtobuf() throws {
        let fungibleTokenType = try TokenType.fromProtobuf(Proto_TokenType.fungibleCommon)
        let nftTokenType = try TokenType.fromProtobuf(Proto_TokenType.nonFungibleUnique)

        XCTAssertEqual(fungibleTokenType, TokenType.fungibleCommon)
        XCTAssertEqual(nftTokenType, TokenType.nonFungibleUnique)
    }
}
