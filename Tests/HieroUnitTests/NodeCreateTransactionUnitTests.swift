// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class NodeCreateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = NodeCreateTransaction

    internal static let testDescription = "test description"
    internal static let testGossipCertificate = Data([0x01, 0x02, 0x03, 0x04])
    internal static let testGrpcCertificateHash = Data([0x05, 0x06, 0x07, 0x08])

    private static func spawnTestEndpoint(offset: Int32) -> Endpoint {
        Endpoint(ipAddress: IPv4Address("127.0.0.1:50222"), port: 42 + offset, domainName: "unit.test.com")
    }

    private static func spawnTestEndpointList(offset: Int32) -> [Endpoint] {
        [Self.spawnTestEndpoint(offset: offset), Self.spawnTestEndpoint(offset: offset + 1)]
    }

    static func makeTransaction() throws -> NodeCreateTransaction {
        try NodeCreateTransaction()
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .accountId(AccountId.fromString("0.0.5007"))
            .description(testDescription)
            .gossipEndpoints(spawnTestEndpointList(offset: 0))
            .serviceEndpoints(spawnTestEndpointList(offset: 2))
            .gossipCaCertificate(Self.testGossipCertificate)
            .grpcCertificateHash(Self.testGrpcCertificateHash)
            .grpcWebProxyEndpoint(spawnTestEndpoint(offset: 4))
            .adminKey(Key.single(TestConstants.privateKey.publicKey))
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
        let gossipEndpoints = Self.spawnTestEndpointList(offset: 0)
        let serviceEndpoints = Self.spawnTestEndpointList(offset: 2)
        let grpcProxyEndpoint = Self.spawnTestEndpoint(offset: 4)
        let protoData = Com_Hedera_Hapi_Node_Addressbook_NodeCreateTransactionBody.with { proto in
            proto.accountID = TestConstants.accountId.toProtobuf()
            proto.description_p = Self.testDescription
            proto.gossipEndpoint = gossipEndpoints.map { $0.toProtobuf() }
            proto.serviceEndpoint = serviceEndpoints.map { $0.toProtobuf() }
            proto.gossipCaCertificate = Self.testGossipCertificate
            proto.grpcCertificateHash = Self.testGrpcCertificateHash
            proto.adminKey = Key.single(TestConstants.publicKey).toProtobuf()
            proto.grpcProxyEndpoint = grpcProxyEndpoint.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.nodeCreate = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try NodeCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.accountId, TestConstants.accountId)
        XCTAssertEqual(tx.adminKey, Key.single(TestConstants.publicKey))
        XCTAssertEqual(tx.description, Self.testDescription)
        XCTAssertEqual(tx.gossipCaCertificate, Self.testGossipCertificate)
        XCTAssertEqual(tx.grpcCertificateHash, Self.testGrpcCertificateHash)
        XCTAssertEqual(tx.gossipEndpoints.count, 2)
        XCTAssertEqual(tx.serviceEndpoints.count, 2)

        for (index, endpoint) in tx.gossipEndpoints.enumerated() {
            XCTAssertEqual(endpoint.ipAddress, gossipEndpoints[index].ipAddress)
            XCTAssertEqual(endpoint.port, gossipEndpoints[index].port)
            XCTAssertEqual(endpoint.domainName, gossipEndpoints[index].domainName)
        }

        for (index, endpoint) in tx.serviceEndpoints.enumerated() {
            XCTAssertEqual(endpoint.ipAddress, serviceEndpoints[index].ipAddress)
            XCTAssertEqual(endpoint.port, serviceEndpoints[index].port)
            XCTAssertEqual(endpoint.domainName, serviceEndpoints[index].domainName)
        }

        XCTAssertEqual(tx.grpcWebProxyEndpoint?.ipAddress, grpcProxyEndpoint.ipAddress)
        XCTAssertEqual(tx.grpcWebProxyEndpoint?.port, grpcProxyEndpoint.port)
        XCTAssertEqual(tx.grpcWebProxyEndpoint?.domainName, grpcProxyEndpoint.domainName)
    }

    internal func test_GetSetAccountId() throws {
        let tx = NodeCreateTransaction()
        tx.accountId(TestConstants.accountId)

        XCTAssertEqual(tx.accountId, TestConstants.accountId)
    }

    internal func test_GetSetAdminKey() throws {
        let tx = NodeCreateTransaction()
        tx.adminKey(.single(TestConstants.publicKey))

        XCTAssertEqual(tx.adminKey, .single(TestConstants.publicKey))
    }

    internal func test_GetSetDescription() throws {
        let tx = NodeCreateTransaction()
        tx.description(Self.testDescription)

        XCTAssertEqual(tx.description, Self.testDescription)
    }

    internal func test_GetSetGossipEndpoints() throws {
        let tx = NodeCreateTransaction()
        let endpoints = Self.spawnTestEndpointList(offset: Int32(0))
        tx.gossipEndpoints(endpoints)

        for (index, endpoint) in tx.gossipEndpoints.enumerated() {
            XCTAssertEqual(endpoint.ipAddress, endpoints[index].ipAddress)
            XCTAssertEqual(endpoint.port, endpoints[index].port)
            XCTAssertEqual(endpoint.domainName, endpoints[index].domainName)
        }
    }

    internal func test_GetSetServiceEndpoints() throws {
        let tx = NodeCreateTransaction()
        let endpoints = Self.spawnTestEndpointList(offset: Int32(2))
        tx.serviceEndpoints(endpoints)

        for (index, endpoint) in tx.serviceEndpoints.enumerated() {
            XCTAssertEqual(endpoint.ipAddress, endpoints[index].ipAddress)
            XCTAssertEqual(endpoint.port, endpoints[index].port)
            XCTAssertEqual(endpoint.domainName, endpoints[index].domainName)
        }
    }

    internal func test_GetSetGossipCaCertificate() throws {
        let tx = NodeCreateTransaction()
        tx.gossipCaCertificate(Self.testGossipCertificate)

        XCTAssertEqual(tx.gossipCaCertificate, Self.testGossipCertificate)
    }

    internal func test_GetSetGrpcCertificateHash() throws {
        let tx = NodeCreateTransaction()
        tx.grpcCertificateHash(Self.testGrpcCertificateHash)

        XCTAssertEqual(tx.grpcCertificateHash, Self.testGrpcCertificateHash)
    }

    internal func test_GetSetGrpcWebProxyEndpoint() throws {
        let tx = NodeCreateTransaction()
        let endpoint = Self.spawnTestEndpoint(offset: 4)
        tx.grpcWebProxyEndpoint(endpoint)

        XCTAssertEqual(tx.grpcWebProxyEndpoint?.ipAddress, endpoint.ipAddress)
        XCTAssertEqual(tx.grpcWebProxyEndpoint?.port, endpoint.port)
        XCTAssertEqual(tx.grpcWebProxyEndpoint?.domainName, endpoint.domainName)
    }
}
