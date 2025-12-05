// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TokenPauseTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TokenPauseTransaction

    private static let testTokenId: TokenId = "4.2.0"

    static func makeTransaction() throws -> TokenPauseTransaction {
        try TokenPauseTransaction()
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
        let protoData = Proto_TokenPauseTransactionBody.with { proto in
            proto.token = Self.testTokenId.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenPause = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TokenPauseTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }

    internal func test_GetSetTokenId() {
        let tx = TokenPauseTransaction()
        tx.tokenId(Self.testTokenId)

        XCTAssertEqual(tx.tokenId, Self.testTokenId)
    }
}
