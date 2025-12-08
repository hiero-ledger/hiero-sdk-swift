// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenUnpauseTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenUnpauseTransaction

    private static let testTokenId: TokenId = "4.2.0"

    static func makeTransaction() throws -> TokenUnpauseTransaction {
        try TokenUnpauseTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .tokenId(testTokenId)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_TokenUnpauseTransactionBody.with { proto in
            proto.token = Self.testTokenId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenUnpause = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenUnpauseTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func test_GetSetTokenId() {
        let tx = TokenUnpauseTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }
}
