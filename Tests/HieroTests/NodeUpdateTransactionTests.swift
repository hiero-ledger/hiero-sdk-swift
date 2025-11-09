// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs
import Network
import SnapshotTesting
import SwiftProtobuf
import XCTest

@testable import Hiero

internal final class NodeUpdateTransactionTests: XCTestCase {
    internal static let testDescription = "test description"
    internal static let testGossipCertificate = Data([0x01, 0x02, 0x03, 0x04])
    internal static let testGrpcCertificateHash = Data([0x05, 0x06, 0x07, 0x08])

    private static func spawnTestEndpoint(offset: Int32) -> Endpoint {
        Endpoint(ipAddress: IPv4Address("127.0.0.1:50211"), port: 20 + offset, domainName: "unit.test.com")
    }

    private static func spawnTestEndpointList(offset: Int32) -> [Endpoint] {
        [Self.spawnTestEndpoint(offset: offset), Self.spawnTestEndpoint(offset: offset + 1)]
    }

    private static func makeTransaction() throws -> NodeUpdateTransaction {
        try NodeUpdateTransaction()
            .nodeId(1)
            .nodeAccountIds([AccountId("0.0.5005"), AccountId("0.0.5006")])
            .transactionId(
                TransactionId(
                    accountId: 5005, validStart: Timestamp(seconds: 1_554_158_542, subSecondNanos: 0), scheduled: false)
            )
            .accountId(AccountId.fromString("0.0.5007"))
            .description(testDescription)
            .gossipEndpoints(Self.spawnTestEndpointList(offset: 1))
            .serviceEndpoints(Self.spawnTestEndpointList(offset: 3))
            .gossipCaCertificate(Self.testGossipCertificate)
            .grpcCertificateHash(Self.testGrpcCertificateHash)
            .grpcWebProxyEndpoint(spawnTestEndpoint(offset: 5))
            .adminKey(Key.single(Resources.privateKey.publicKey))
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
        let gossipEndpoints = Self.spawnTestEndpointList(offset: 1)
        let serviceEndpoints = Self.spawnTestEndpointList(offset: 3)
        let grpcProxyEndpoint = Self.spawnTestEndpoint(offset: 5)
        let protoData = Com_Hedera_Hapi_Node_Addressbook_NodeUpdateTransactionBody.with { proto in
            proto.accountID = Resources.accountId.toProtobuf()
            proto.description_p = Google_Protobuf_StringValue(Self.testDescription)
            proto.gossipEndpoint = gossipEndpoints.map { $0.toProtobuf() }
            proto.serviceEndpoint = serviceEndpoints.map { $0.toProtobuf() }
            proto.gossipCaCertificate = Google_Protobuf_BytesValue(Self.testGossipCertificate)
            proto.grpcCertificateHash = Google_Protobuf_BytesValue(Self.testGrpcCertificateHash)
            proto.adminKey = Key.single(Resources.publicKey).toProtobuf()
            proto.grpcProxyEndpoint = grpcProxyEndpoint.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.nodeUpdate = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try NodeUpdateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.nodeId, 0)
        XCTAssertEqual(tx.accountId, Resources.accountId)
        XCTAssertEqual(tx.adminKey, Key.single(Resources.publicKey))
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

    internal func testGetSetNodeId() throws {
        let tx = NodeUpdateTransaction()
        tx.nodeId(1)

        XCTAssertEqual(tx.nodeId, 1)
    }

    internal func testGetSetAccountId() throws {
        let tx = NodeUpdateTransaction()
        tx.accountId(Resources.accountId)

        XCTAssertEqual(tx.accountId, Resources.accountId)
    }

    internal func testGetSetAdminKey() throws {
        let tx = NodeUpdateTransaction()
        tx.adminKey(.single(Resources.publicKey))

        XCTAssertEqual(tx.adminKey, .single(Resources.publicKey))
    }

    internal func testGetSetDescription() throws {
        let tx = NodeUpdateTransaction()
        tx.description(Self.testDescription)

        XCTAssertEqual(tx.description, Self.testDescription)
    }

    internal func testGetSetGossipEndpoints() throws {
        let tx = NodeUpdateTransaction()
        let endpoints = Self.spawnTestEndpointList(offset: Int32(4))
        tx.gossipEndpoints(endpoints)

        for (index, endpoint) in tx.gossipEndpoints.enumerated() {
            XCTAssertEqual(endpoint.ipAddress, endpoints[index].ipAddress)
            XCTAssertEqual(endpoint.port, endpoints[index].port)
            XCTAssertEqual(endpoint.domainName, endpoints[index].domainName)
        }
    }

    internal func testGetSetServiceEndpoints() throws {
        let tx = NodeUpdateTransaction()
        let endpoints = Self.spawnTestEndpointList(offset: Int32(4))
        tx.serviceEndpoints(endpoints)

        for (index, endpoint) in tx.serviceEndpoints.enumerated() {
            XCTAssertEqual(endpoint.ipAddress, endpoints[index].ipAddress)
            XCTAssertEqual(endpoint.port, endpoints[index].port)
            XCTAssertEqual(endpoint.domainName, endpoints[index].domainName)
        }
    }

    internal func testGetSetGossipCaCertificate() throws {
        let tx = NodeUpdateTransaction()
        tx.gossipCaCertificate(Self.testGossipCertificate)

        XCTAssertEqual(tx.gossipCaCertificate, Self.testGossipCertificate)
    }

    internal func testGetSetGrpcCertificateHash() throws {
        let tx = NodeUpdateTransaction()
        tx.grpcCertificateHash(Self.testGrpcCertificateHash)

        XCTAssertEqual(tx.grpcCertificateHash, Self.testGrpcCertificateHash)
    }

    internal func testGetSetGrpcWebProxyEndpoint() throws {
        let tx = NodeUpdateTransaction()
        let endpoint = Self.spawnTestEndpoint(offset: 5)
        tx.grpcWebProxyEndpoint(endpoint)

        XCTAssertEqual(tx.grpcWebProxyEndpoint?.ipAddress, endpoint.ipAddress)
        XCTAssertEqual(tx.grpcWebProxyEndpoint?.port, endpoint.port)
        XCTAssertEqual(tx.grpcWebProxyEndpoint?.domainName, endpoint.domainName)
    }
}
