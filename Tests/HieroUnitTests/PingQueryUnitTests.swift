// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class PingQueryUnitTests: HieroUnitTestCase, QueryTestable {
    static func makeQueryProto() throws -> Proto_Query {
        try PingQuery(nodeAccountId: AccountId(num: 3)).makeRequest(nil, AccountId(num: 3)).0
    }

    internal func test_Serialize() throws {
        try assertQuerySerializes()
    }

    internal func test_ProbeIsCostAnswerGetAccountInfoForAccount2() throws {
        let proto = try Self.makeQueryProto()

        guard case .cryptoGetInfo(let query) = proto.query else {
            return XCTFail("expected `cryptoGetInfo`, got \(String(describing: proto.query))")
        }

        XCTAssertEqual(query.header.responseType, .costAnswer)
        XCTAssertEqual(try AccountId.fromProtobuf(query.accountID), AccountId(num: 2))
        XCTAssertFalse(query.header.hasPayment)
    }

    internal func test_ProbeUsesNodeShardAndRealm() throws {
        let node = AccountId(shard: 1, realm: 2, num: 7)
        let proto = try PingQuery(nodeAccountId: node).makeRequest(nil, node).0

        XCTAssertEqual(try AccountId.fromProtobuf(proto.cryptoGetInfo.accountID), AccountId(shard: 1, realm: 2, num: 2))
    }

    internal func test_MakeResponseRejectsWrongResponseKind() {
        let response = Proto_Response.with { $0.cryptogetAccountBalance = .init() }

        XCTAssertThrowsError(try PingQuery(nodeAccountId: 3).makeResponse(response, (), 3, nil))
    }
}
