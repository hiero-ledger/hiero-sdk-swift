// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SwiftProtobuf
import XCTest

@testable import Hiero

internal final class RegisteredNodeUpdateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    internal typealias TransactionType = RegisteredNodeUpdateTransaction

    internal static let testDescription = "updated block node"
    internal static let testRegisteredNodeId: UInt64 = 42

    private static func spawnTestEndpoint() -> RegisteredServiceEndpoint {
        .blockNode(
            address: .ipAddress(Data([127, 0, 0, 1])),
            port: 8080,
            requiresTls: true,
            endpointApis: [.status]
        )
    }

    internal static func makeTransaction() throws -> RegisteredNodeUpdateTransaction {
        try RegisteredNodeUpdateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .registeredNodeId(testRegisteredNodeId)
            .adminKey(Key.single(TestConstants.privateKey.publicKey))
            .description(testDescription)
            .addServiceEndpoint(spawnTestEndpoint())
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
        let endpoint = Self.spawnTestEndpoint()
        let protoData = Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeUpdateTransactionBody.with { proto in
            proto.registeredNodeID = Self.testRegisteredNodeId
            proto.adminKey = Key.single(TestConstants.publicKey).toProtobuf()
            proto.description_p = Google_Protobuf_StringValue(Self.testDescription)
            proto.serviceEndpoint = [endpoint.toProtobuf()]
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.registeredNodeUpdate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try RegisteredNodeUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.registeredNodeId, Self.testRegisteredNodeId)
        XCTAssertEqual(tx.adminKey, Key.single(TestConstants.publicKey))
        XCTAssertEqual(tx.description, Self.testDescription)
        XCTAssertEqual(tx.serviceEndpoints.count, 1)
    }

    internal func test_GetSetRegisteredNodeId() throws {
        let tx = RegisteredNodeUpdateTransaction()
        tx.registeredNodeId(Self.testRegisteredNodeId)

        XCTAssertEqual(tx.registeredNodeId, Self.testRegisteredNodeId)
    }

    internal func test_GetSetAdminKey() throws {
        let tx = RegisteredNodeUpdateTransaction()
        tx.adminKey(.single(TestConstants.publicKey))

        XCTAssertEqual(tx.adminKey, .single(TestConstants.publicKey))
    }

    internal func test_GetSetDescription() throws {
        let tx = RegisteredNodeUpdateTransaction()
        tx.description(Self.testDescription)

        XCTAssertEqual(tx.description, Self.testDescription)
    }

    internal func test_GetSetServiceEndpoints() throws {
        let tx = RegisteredNodeUpdateTransaction()
        let endpoint = Self.spawnTestEndpoint()
        tx.serviceEndpoints([endpoint])

        XCTAssertEqual(tx.serviceEndpoints.count, 1)
    }

    internal func test_AddServiceEndpoint() throws {
        let tx = RegisteredNodeUpdateTransaction()
        tx.addServiceEndpoint(Self.spawnTestEndpoint())
        tx.addServiceEndpoint(.rpcRelay(address: .domainName("rpc.example.com"), port: 443, requiresTls: true))

        XCTAssertEqual(tx.serviceEndpoints.count, 2)
    }

    internal func test_NullDescription() throws {
        let protoData = Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeUpdateTransactionBody.with { proto in
            proto.registeredNodeID = Self.testRegisteredNodeId
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.registeredNodeUpdate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try RegisteredNodeUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertNil(tx.description)
    }
}
