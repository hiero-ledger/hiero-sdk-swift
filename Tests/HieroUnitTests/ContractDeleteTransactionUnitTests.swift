// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ContractDeleteTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = ContractDeleteTransaction

    static func makeTransaction() throws -> ContractDeleteTransaction {
        try ContractDeleteTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .contractId(5007)
            .transferAccountId("0.0.9")
            .transferContractId("0.0.5008")
            .maxTransactionFee(.fromTinybars(100_000))
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_ContractDeleteTransactionBody.with { proto in
            proto.contractID = ContractId(num: 5007).toProtobuf()
            proto.transferAccountID = AccountId(num: 9).toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.contractDeleteInstance = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try ContractDeleteTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.contractId, 5007)
        XCTAssertEqual(tx.transferAccountId, 9)
        XCTAssertEqual(tx.transferContractId, nil)
    }

    internal func test_GetSetContractId() {
        let tx = ContractDeleteTransaction()
        tx.contractId(5007)

        XCTAssertEqual(tx.contractId, 5007)
    }
    internal func test_GetSetTransferAccountId() {
        let tx = ContractDeleteTransaction()
        tx.transferAccountId(9)

        XCTAssertEqual(tx.transferAccountId, 9)
    }
    internal func test_GetSetTransferContractId() {
        let tx = ContractDeleteTransaction()
        tx.transferContractId(5008)

        XCTAssertEqual(tx.transferContractId, 5008)
    }
}
