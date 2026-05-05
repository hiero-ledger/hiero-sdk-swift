// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class RegisteredNodeDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    internal typealias TransactionType = RegisteredNodeDeleteTransaction

    internal static let testRegisteredNodeId: UInt64 = 42

    internal static func makeTransaction() throws -> RegisteredNodeDeleteTransaction {
        try RegisteredNodeDeleteTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .registeredNodeId(testRegisteredNodeId)
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
        let protoData = Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeDeleteTransactionBody.with { proto in
            proto.registeredNodeID = Self.testRegisteredNodeId
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.registeredNodeDelete = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try RegisteredNodeDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.registeredNodeId, Self.testRegisteredNodeId)
    }

    internal func test_GetSetRegisteredNodeId() throws {
        let tx = RegisteredNodeDeleteTransaction()
        tx.registeredNodeId(Self.testRegisteredNodeId)

        XCTAssertEqual(tx.registeredNodeId, Self.testRegisteredNodeId)
    }
}
