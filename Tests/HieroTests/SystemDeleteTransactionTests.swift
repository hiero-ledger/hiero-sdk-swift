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

internal final class SystemDeleteTransactionTests: XCTestCase {
    private static let contractId: ContractId = 444
    private static let fileId: FileId = 444
    private static let expirationTime = Resources.validStart

    internal static func makeTransactionFile() throws -> SystemDeleteTransaction {
        try SystemDeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .fileId(fileId)
            .expirationTime(expirationTime)
            .freeze()
    }

    internal static func makeTransactionContract() throws -> SystemDeleteTransaction {
        try SystemDeleteTransaction()
            .nodeAccountIds(Resources.nodeAccountIds)
            .transactionId(Resources.txId)
            .sign(Resources.privateKey)
            .contractId(444)
            .expirationTime(Resources.validStart)
            .freeze()
    }

    internal func testSerializeFile() throws {
        let tx = try Self.makeTransactionFile().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytesFile() throws {
        let tx = try Self.makeTransactionFile()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testSerializeContract() throws {
        let tx = try Self.makeTransactionContract().makeProtoBody()

        assertSnapshot(matching: tx, as: .description)
    }

    internal func testToFromBytesContract() throws {
        let tx = try Self.makeTransactionContract()

        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func testFromProtoBody() throws {
        let protoData = Proto_SystemDeleteTransactionBody.with { proto in
            proto.fileID = Self.fileId.toProtobuf()
            proto.expirationTime = .with { $0.seconds = Self.expirationTime.toProtobuf().seconds }
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.systemDelete = protoData
            proto.transactionID = Resources.txId.toProtobuf()
        }

        let tx = try SystemDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.fileId, Self.fileId)
        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
        XCTAssertEqual(tx.contractId, nil)
    }

    internal func testGetSetFileId() {
        let tx = SystemDeleteTransaction()
        tx.fileId(Self.fileId)

        XCTAssertEqual(tx.fileId, Self.fileId)
    }

    internal func testGetSetContractId() throws {
        let tx = SystemDeleteTransaction()
        tx.contractId(Self.contractId)

        XCTAssertEqual(tx.contractId, Self.contractId)
    }

    internal func testGetSetExpirationTime() throws {
        let tx = SystemDeleteTransaction()
        tx.expirationTime(Self.expirationTime)

        XCTAssertEqual(tx.expirationTime, Self.expirationTime)
    }
}
