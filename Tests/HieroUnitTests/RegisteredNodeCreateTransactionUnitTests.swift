// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class RegisteredNodeCreateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    internal typealias TransactionType = RegisteredNodeCreateTransaction

    internal static let testDescription = "test block node"

    private static func spawnTestEndpoint() -> RegisteredServiceEndpoint {
        .blockNode(
            address: .ipAddress(Data([127, 0, 0, 1])),
            port: 8080,
            requiresTls: true,
            endpointApis: [.subscribeStream]
        )
    }

    internal static func makeTransaction() throws -> RegisteredNodeCreateTransaction {
        try RegisteredNodeCreateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
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
        let protoData = Com_Hedera_Hapi_Node_Addressbook_RegisteredNodeCreateTransactionBody.with { proto in
            proto.adminKey = Key.single(TestConstants.publicKey).toProtobuf()
            proto.description_p = Self.testDescription
            proto.serviceEndpoint = [endpoint.toProtobuf()]
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.registeredNodeCreate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try RegisteredNodeCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.adminKey, Key.single(TestConstants.publicKey))
        XCTAssertEqual(tx.description, Self.testDescription)
        XCTAssertEqual(tx.serviceEndpoints.count, 1)
    }

    internal func test_GetSetAdminKey() throws {
        let tx = RegisteredNodeCreateTransaction()
        tx.adminKey(.single(TestConstants.publicKey))

        XCTAssertEqual(tx.adminKey, .single(TestConstants.publicKey))
    }

    internal func test_GetSetDescription() throws {
        let tx = RegisteredNodeCreateTransaction()
        tx.description(Self.testDescription)

        XCTAssertEqual(tx.description, Self.testDescription)
    }

    internal func test_GetSetServiceEndpoints() throws {
        let tx = RegisteredNodeCreateTransaction()
        let endpoint = Self.spawnTestEndpoint()
        tx.serviceEndpoints([endpoint])

        XCTAssertEqual(tx.serviceEndpoints.count, 1)
    }

    internal func test_AddServiceEndpoint() throws {
        let tx = RegisteredNodeCreateTransaction()
        tx.addServiceEndpoint(Self.spawnTestEndpoint())
        tx.addServiceEndpoint(.mirrorNode(address: .domainName("mirror.example.com"), port: 443, requiresTls: true))

        XCTAssertEqual(tx.serviceEndpoints.count, 2)
    }
}
