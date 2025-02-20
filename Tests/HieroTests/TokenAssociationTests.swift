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

internal final class TokenAssociationTests: XCTestCase {
    private static let association: TokenAssociation = .init(tokenId: "1.2.3", accountId: 5006)

    internal func testSerialize() throws {
        let bytes = TokenAssociation(tokenId: "1.2.3", accountId: "1.2.4").toBytes()

        let association = try TokenAssociation.fromBytes(bytes)

        assertSnapshot(matching: association, as: .description)
    }

    internal func testFromProtobuf() throws {
        let proto = Self.association.toProtobuf()

        let association = try TokenAssociation.fromProtobuf(proto)

        XCTAssertEqual(association.accountId, 5006)
        XCTAssertEqual(association.tokenId, "1.2.3")
    }

    internal func testToProtobuf() throws {
        let proto = Self.association.toProtobuf()

        XCTAssertTrue(proto.hasAccountID)
        XCTAssertEqual(proto.accountID, AccountId(num: 5006).toProtobuf())

        XCTAssertTrue(proto.hasTokenID)
        XCTAssertEqual(proto.tokenID, TokenId(shard: 1, realm: 2, num: 3).toProtobuf())
    }

    internal func testToBytes() throws {
        let bytes = Self.association.toBytes()

        XCTAssertEqual(bytes, try Self.association.toProtobuf().serializedData())
    }
}
