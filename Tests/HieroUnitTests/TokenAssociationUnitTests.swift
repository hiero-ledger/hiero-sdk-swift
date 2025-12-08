// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenAssociationUnitTests: HieroUnitTestCase {
    private static let association: TokenAssociation = .init(tokenId: "1.2.3", accountId: 5006)

    internal func test_Serialize() throws {
        let bytes = TokenAssociation(tokenId: "1.2.3", accountId: "1.2.4").toBytes()

        let association = try TokenAssociation.fromBytes(bytes)

        SnapshotTesting.assertSnapshot(of: association, as: .description)
    }

    internal func test_FromProtobuf() throws {
        let proto = Self.association.toProtobuf()

        let association = try TokenAssociation.fromProtobuf(proto)

        XCTAssertEqual(association.accountId, 5006)
        XCTAssertEqual(association.tokenId, "1.2.3")
    }

    internal func test_ToProtobuf() throws {
        let proto = Self.association.toProtobuf()

        XCTAssertTrue(proto.hasAccountID)
        XCTAssertEqual(proto.accountID, AccountId(num: 5006).toProtobuf())

        XCTAssertTrue(proto.hasTokenID)
        XCTAssertEqual(proto.tokenID, TokenId(shard: 1, realm: 2, num: 3).toProtobuf())
    }

    internal func test_ToBytes() throws {
        let bytes = Self.association.toBytes()

        XCTAssertEqual(bytes, try Self.association.toProtobuf().serializedData())
    }
}
