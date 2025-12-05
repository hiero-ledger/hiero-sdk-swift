// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TopicCreateTransactionUnitTests: HieroUnitTestCase, TransactionTestable {
    typealias TransactionType = TopicCreateTransaction

    private static let testAutoRenewAccountId: AccountId = "0.0.5007"
    private static let testAutoRenewPeriod: Duration = .days(1)

    static func makeTransaction() throws -> TopicCreateTransaction {
        try TopicCreateTransaction()
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .sign(TestConstants.privateKey)
            .submitKey(.single(TestConstants.publicKey))
            .adminKey(.single(TestConstants.publicKey))
            .autoRenewAccountId(testAutoRenewAccountId)
            .autoRenewPeriod(testAutoRenewPeriod)
            .freeze()
    }

    internal func test_Serialize() throws {
        try assertTransactionSerializes()
    }

    internal func test_ToFromBytes() throws {
        try assertTransactionRoundTrips()
    }

    internal func test_FromProtoBody() throws {
        let protoData = Proto_ConsensusCreateTopicTransactionBody.with { proto in
            proto.submitKey = TestConstants.publicKey.toProtobuf()
            proto.adminKey = TestConstants.publicKey.toProtobuf()
            proto.autoRenewAccount = Self.testAutoRenewAccountId.toProtobuf()
            proto.autoRenewPeriod = Self.testAutoRenewPeriod.toProtobuf()
        }

        let protoBody = Proto_TransactionBody.with { proto in
            proto.consensusCreateTopic = protoData
            proto.transactionID = TestConstants.transactionId.toProtobuf()
        }

        let tx = try TopicCreateTransaction(protobuf: protoBody, protoData)

        XCTAssertEqual(tx.submitKey, .single(TestConstants.publicKey))
        XCTAssertEqual(tx.adminKey, .single(TestConstants.publicKey))
        XCTAssertEqual(tx.autoRenewAccountId, Self.testAutoRenewAccountId)
        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
    }

    internal func test_GetSetSubmitKey() {
        let tx = TopicCreateTransaction()
        tx.submitKey(.single(TestConstants.publicKey))

        XCTAssertEqual(tx.submitKey, .single(TestConstants.publicKey))
    }

    internal func test_GetSetAdminKey() {
        let tx = TopicCreateTransaction()
        tx.adminKey(.single(TestConstants.publicKey))

        XCTAssertEqual(tx.adminKey, .single(TestConstants.publicKey))
    }

    internal func test_GetSetAutoRenewAccountId() {
        let tx = TopicCreateTransaction()
        tx.autoRenewAccountId(Self.testAutoRenewAccountId)

        XCTAssertEqual(tx.autoRenewAccountId, Self.testAutoRenewAccountId)
    }

    internal func test_GetSetAutoRenewPeriod() {
        let tx = TopicCreateTransaction()
        tx.autoRenewPeriod(Self.testAutoRenewPeriod)

        XCTAssertEqual(tx.autoRenewPeriod, Self.testAutoRenewPeriod)
    }

    internal func test_AutomaticallySetAutoRenewAccountId() throws {
        let tx = TopicCreateTransaction()
        tx.transactionId(TestConstants.transactionId)
        tx.nodeAccountIds(TestConstants.nodeAccountIds)
        try tx.freezeWith(nil)

        XCTAssertEqual(tx.autoRenewAccountId, TestConstants.transactionId.accountId)
    }
}
