/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
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
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class TokenRejectTransactionTests: XCTestCase {
    private static let testPrivateKey = PrivateKey(
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e10")
    private static let testOwnerId = AccountId("0.0.12345")

    private static let testTokenIds: [TokenId] = [TokenId("4.2.0"), TokenId("4.2.1"), TokenId("4.2.2")]

    private static let testNftIds: [NftId] = [NftId("4.2.3/1"), NftId("4.2.4/2"), NftId("4.2.5/3")]

    private static func makeTransaction() throws -> TokenRejectTransaction {
        try TokenRejectTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .owner(testOwnerId)
            .tokenIds(testTokenIds)
            .nftIds(testNftIds)
            .freeze()
            .sign(testPrivateKey)
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
        var protoTokenReferences: [Proto_TokenReference] = []

        for tokenId in Self.testTokenIds {
            protoTokenReferences.append(.with { $0.fungibleToken = tokenId.toProtobuf() })
        }

        for nftId in Self.testNftIds {
            protoTokenReferences.append(.with { $0.nft = nftId.toProtobuf() })
        }

        let protoData = Proto_TokenRejectTransactionBody.with { proto in
            proto.owner = Self.testOwnerId.toProtobuf()
            proto.rejections = protoTokenReferences
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.tokenReject = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try TokenRejectTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.owner, Self.testOwnerId)
        XCTAssertEqual(tx.tokenIds, Self.testTokenIds)
        XCTAssertEqual(tx.nftIds, Self.testNftIds)
    }

    internal func testGetSetOwner() {
        let tx = TokenRejectTransaction()
        tx.owner(Self.testOwnerId)

        XCTAssertEqual(tx.owner, Self.testOwnerId)
    }

    internal func testGetSetTokenIds() {
        let tx = TokenRejectTransaction()
        tx.tokenIds(Self.testTokenIds)

        XCTAssertEqual(tx.tokenIds, Self.testTokenIds)
    }

    internal func testGetSetNftIds() {
        let tx = TokenRejectTransaction()
        tx.nftIds(Self.testNftIds)

        XCTAssertEqual(tx.nftIds, Self.testNftIds)
    }

    internal func testGetSetAddTokenId() {
        let tx = TokenRejectTransaction()
        tx.addTokenId(Self.testTokenIds[0])
        tx.addTokenId(Self.testTokenIds[1])

        XCTAssertEqual(tx.tokenIds[0], Self.testTokenIds[0])
        XCTAssertEqual(tx.tokenIds[1], Self.testTokenIds[1])
    }

    internal func testGetSetAddNftId() {
        let tx = TokenRejectTransaction()
        tx.addNftId(Self.testNftIds[0])
        tx.addNftId(Self.testNftIds[1])

        XCTAssertEqual(tx.nftIds[0], Self.testNftIds[0])
        XCTAssertEqual(tx.nftIds[1], Self.testNftIds[1])
    }
}
