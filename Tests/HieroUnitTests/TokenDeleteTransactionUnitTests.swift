// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenDeleteTransaction

    static func makeTransaction() throws -> TokenDeleteTransaction {
        try TokenDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .tokenId("1.2.3")
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_TokenDeleteTransactionBody.with { proto in
            proto.token = TokenId(shard: 1, realm: 2, num: 3).toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenDeletion = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.tokenId, "1.2.3")
    }

    internal func test_GetSetTokenId() {
        let tx = TokenDeleteTransaction()

        tx.tokenId("1.2.3")
        XCTAssertEqual(tx.tokenId, "1.2.3")
    }
}
