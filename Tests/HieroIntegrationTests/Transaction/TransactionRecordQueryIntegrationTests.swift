// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TransactionRecordQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_Query() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let txResponse = try await TopicCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .topicMemo("[e2e::TransactionReceipt]")
            .execute(testEnv.client)
        let txId = try XCTUnwrap(txResponse.transactionId)

        // When / Then
        let txRecord = try await TransactionRecordQuery()
            .transactionId(txId)
            .execute(testEnv.client)
        XCTAssertEqual(txId, txRecord.transactionId)

        if let topicId = txRecord.receipt.topicId {
            await registerTopic(topicId, adminKeys: [adminKey])
        }
    }

    internal func test_QueryInvalidTxIdFails() async throws {
        // Given / When / Then
        await assertQueryNoPaymentPrecheckStatus(
            try await TransactionRecordQuery().execute(testEnv.client),
            .invalidTransactionID
        )
    }
}
