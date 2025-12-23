// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class EthereumTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = EthereumTransaction

    private static let ethereumData = "livestock".data(using: .utf8)!
    private static let callDataFileId: FileId = "4.5.6"
    private static let maxGasAllowanceHbar: Hbar = 3

    static func makeTransaction() throws -> EthereumTransaction {
        try EthereumTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .ethereumData(ethereumData)
            .callDataFileId(callDataFileId)
            .maxGasAllowanceHbar(maxGasAllowanceHbar)
            .maxTransactionFee(Hbar(1))
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_EthereumTransactionBody.with { proto in
            proto.ethereumData = Self.ethereumData
            proto.callData = Self.callDataFileId.toProtobuf()
            proto.maxGasAllowance = Self.maxGasAllowanceHbar.tinybars
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.ethereumTransaction = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try EthereumTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.ethereumData, Self.ethereumData)
        XCTAssertEqual(tx.callDataFileId, Self.callDataFileId)
        XCTAssertEqual(tx.maxGasAllowanceHbar, Self.maxGasAllowanceHbar)
    }

    internal func test_GetSetEthereumData() {
        let tx = EthereumTransaction()
        tx.ethereumData(Self.ethereumData)

        XCTAssertEqual(tx.ethereumData, Self.ethereumData)
    }
    internal func test_GetSetCallDataFileId() {
        let tx = EthereumTransaction()
        tx.callDataFileId(Self.callDataFileId)

        XCTAssertEqual(tx.callDataFileId, Self.callDataFileId)
    }
    internal func test_GetSetMaxGasAllowanceHbar() {
        let tx = EthereumTransaction()
        tx.maxGasAllowanceHbar(Self.maxGasAllowanceHbar)

        XCTAssertEqual(tx.maxGasAllowanceHbar, Self.maxGasAllowanceHbar)
    }
}
