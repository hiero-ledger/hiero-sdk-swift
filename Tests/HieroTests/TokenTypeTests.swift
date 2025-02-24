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
