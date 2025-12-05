// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class NodeDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = NodeDeleteTransaction

    static func makeTransaction() throws -> NodeDeleteTransaction {
        try NodeDeleteTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .nodeId(2)
            .freeze()
            .sign(TestConstants.privateKey)
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Com_Hedera_Hapi_Node_Addressbook_NodeDeleteTransactionBody.with { proto in
            proto.nodeID = 2
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.nodeDelete = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try NodeDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.nodeId, 2)
    }

    internal func test_GetSetNodeId() throws {
        let tx = NodeDeleteTransaction()
        tx.nodeId(2)

        XCTAssertEqual(tx.nodeId, 2)
    }
}
