/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import HieroProtobufs
import Network
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class NodeCreateTransactionTests: XCTestCase {
    internal static let testDescription = "test description"
    internal static let testGossipCertificate = Data([0x01, 0x02, 0x03, 0x04])
    internal static let testGrpcCertificateHash = Data([0x05, 0x06, 0x07, 0x08])

    private static func spawnTestEndpoint(offset: Int32) -> Endpoint {
        Endpoint(ipAddress: IPv4Address("127.0.0.1:50222"), port: 42 + offset, domainName: "unit.test.com")
    }

    private static func spawnTestEndpointList(offset: Int32) -> [Endpoint] {
        [Self.spawnTestEndpoint(offset: offset), Self.spawnTestEndpoint(offset: offset + 1)]
    }

    private static func makeTransaction() throws -> NodeCreateTransaction {
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
            .adminKey(Key.single(Resources.privateKey.publicKey))
            .freeze()
            .sign(Resources.privateKey)
    }

    internal func testSerialize() throws {
        let tx = try Self.makeTransaction().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.makeTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let gossipEndpoints = Self.spawnTestEndpointList(offset: 0)
        let serviceEndpoints = Self.spawnTestEndpointList(offset: 2)
        let protoData = Com_Hedera_Hapi_Node_Addressbook_NodeCreateTransactionBody.with { proto in
            proto.accountID = Resources.accountId.toProtobuf()
            proto.description_p = Self.testDescription
            proto.gossipEndpoint = gossipEndpoints.map { $0.toProtobuf() }
            proto.serviceEndpoint = serviceEndpoints.map { $0.toProtobuf() }
            proto.gossipCaCertificate = Self.testGossipCertificate
            proto.grpcCertificateHash = Self.testGrpcCertificateHash
            proto.adminKey = Key.single(Resources.publicKey).toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.nodeCreate = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try NodeCreateTransaction(protobuf: protoBody, protoData)

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
    }

    internal func testGetSetAccountId() throws {
        let tx = NodeCreateTransaction()
        tx.accountId(Resources.accountId)

        XCTAssertEqual(tx.accountId, Resources.accountId)
    }

    internal func testGetSetAdminKey() throws {
        let tx = NodeCreateTransaction()
        tx.adminKey(.single(Resources.publicKey))

        XCTAssertEqual(tx.adminKey, .single(Resources.publicKey))
    }

    internal func testGetSetDescription() throws {
        let tx = NodeCreateTransaction()
        tx.description(Self.testDescription)

        XCTAssertEqual(tx.description, Self.testDescription)
    }

    internal func testGetSetGossipEndpoints() throws {
        let tx = NodeCreateTransaction()
        let endpoints = Self.spawnTestEndpointList(offset: Int32(0))
        tx.gossipEndpoints(endpoints)

        for (index, endpoint) in tx.gossipEndpoints.enumerated() {
            XCTAssertEqual(endpoint.ipAddress, endpoints[index].ipAddress)
            XCTAssertEqual(endpoint.port, endpoints[index].port)
            XCTAssertEqual(endpoint.domainName, endpoints[index].domainName)
        }
    }

    internal func testGetSetServiceEndpoints() throws {
        let tx = NodeCreateTransaction()
        let endpoints = Self.spawnTestEndpointList(offset: Int32(2))
        tx.serviceEndpoints(endpoints)

        for (index, endpoint) in tx.serviceEndpoints.enumerated() {
            XCTAssertEqual(endpoint.ipAddress, endpoints[index].ipAddress)
            XCTAssertEqual(endpoint.port, endpoints[index].port)
            XCTAssertEqual(endpoint.domainName, endpoints[index].domainName)
        }
    }

    internal func testGetSetGossipCaCertificate() throws {
        let tx = NodeCreateTransaction()
        tx.gossipCaCertificate(Self.testGossipCertificate)

        XCTAssertEqual(tx.gossipCaCertificate, Self.testGossipCertificate)
    }

    internal func testGetSetGrpcCertificateHash() throws {
        let tx = NodeCreateTransaction()
        tx.grpcCertificateHash(Self.testGrpcCertificateHash)

        XCTAssertEqual(tx.grpcCertificateHash, Self.testGrpcCertificateHash)
    }
}
