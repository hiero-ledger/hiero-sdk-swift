// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import SnapshotTesting
import SwiftProtobuf
import XCTest

@testable import Hiero

internal final class NodeDeleteTransactionTests: XCTestCase {
    private static func makeTransaction() throws -> NodeDeleteTransaction {
        try NodeDeleteTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .nodeId(2)
            .freeze()
            .sign(Resources.privateKey)
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(of: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Com_Hedera_Hapi_Node_Addressbook_NodeDeleteTransactionBody.with { proto in
            proto.nodeID = 2
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.nodeDelete = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try NodeDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.nodeId, 2)
    }

    internal func testGetSetNodeId() throws {
        let tx = NodeDeleteTransaction()
        tx.nodeId(2)

        XCTAssertEqual(tx.nodeId, 2)
    }
}
