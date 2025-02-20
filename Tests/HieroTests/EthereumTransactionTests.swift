/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
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

internal final class EthereumTransactionTests: XCTestCase {
    private static let ethereumData = "livestock".data(using: .utf8)!
    private static let callDataFileId: FileId = "4.5.6"
    private static let maxGasAllowanceHbar: Hbar = 3

    private static func createTransaction() throws -> EthereumTransaction {
        try EthereumTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .ethereumData(ethereumData)
            .callDataFileId(callDataFileId)
            .maxGasAllowanceHbar(maxGasAllowanceHbar)
            .maxTransactionFee(Hbar(1))
            .freeze()
    }

    internal func testSerialize() throws {
        assertSnapshot(matching: try Self.createTransaction().makeProtoBody(), as: .description)
    }

    internal func testToFromBytes() throws {
        let tx = try Self.createTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_EthereumTransactionBody.with { proto in
            proto.ethereumData = Self.ethereumData
            proto.callData = Self.callDataFileId.toProtobuf()
            proto.maxGasAllowance = Self.maxGasAllowanceHbar.tinybars
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.ethereumTransaction = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try EthereumTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.ethereumData, Self.ethereumData)
        XCTAssertEqual(tx.callDataFileId, Self.callDataFileId)
        XCTAssertEqual(tx.maxGasAllowanceHbar, Self.maxGasAllowanceHbar)
    }

    internal func testGetSetEthereumData() {
        let tx = EthereumTransaction()
        tx.ethereumData(Self.ethereumData)

        XCTAssertEqual(tx.ethereumData, Self.ethereumData)
    }
    internal func testGetSetCallDataFileId() {
        let tx = EthereumTransaction()
        tx.callDataFileId(Self.callDataFileId)

        XCTAssertEqual(tx.callDataFileId, Self.callDataFileId)
    }
    internal func testGetSetMaxGasAllowanceHbar() {
        let tx = EthereumTransaction()
        tx.maxGasAllowanceHbar(Self.maxGasAllowanceHbar)

        XCTAssertEqual(tx.maxGasAllowanceHbar, Self.maxGasAllowanceHbar)
    }
}
