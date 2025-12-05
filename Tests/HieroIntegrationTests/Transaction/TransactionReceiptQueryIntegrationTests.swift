// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal class TransactionReceiptQueryIntegrationTests: HieroIntegrationTestCase {
    internal func test_Query() async throws {
        // Given
        let adminKey = PrivateKey.generateEd25519()
        let txResponse = try await TopicCreateTransaction()
            .adminKey(.single(adminKey.publicKey))
            .topicMemo("[e2e::TransactionReceipt]")
            .execute(testEnv.client)
        let txId = try XCTUnwrap(txResponse.transactionId)

        // When / Then
        let txReceipt = try await TransactionReceiptQuery()
            .transactionId(txId)
            .execute(testEnv.client)

        if let topicId = txReceipt.topicId {
            await registerTopic(topicId, adminKeys: [adminKey])
        }
    }

    internal func test_QueryInvalidTxIdFails() async throws {
        // Given / When / Then
        await assertThrowsHErrorAsync(
            try await TransactionReceiptQuery()
                .execute(testEnv.client),
            "expected error querying transaction receipt"
        ) { error in
            guard case .queryNoPaymentPreCheckStatus(let status) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryNoPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidTransactionID)
        }
    }
}
