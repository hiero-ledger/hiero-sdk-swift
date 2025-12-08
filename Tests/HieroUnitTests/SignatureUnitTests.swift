// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import SnapshotTesting
import XCTest

@testable import Hiero

internal final class SignatureUnitTests: HieroUnitTestCase {
    internal static var firstPrivateKey: PrivateKey =
        "302e020100300506032b657004220420e40d4241d093b22910c78135e0501b137cd9205bbb9c0153c5adf2c65e7dc95a"
    internal static var secondPrivateKey: PrivateKey =
        "302e020100300506032b657004220420e40d4241d093b22910c78135e0501b137cd9205bbb9c0153c5adf2c65e7dc85b"

    internal func test_GetSignatures() throws {
        let new = TransferTransaction()

        let bodyBytes = try new.maxTransactionFee(10).transactionValidDuration(Duration.seconds(119))
            .transactionMemo("Frosted flakes").hbarTransfer(AccountId(2), 2).hbarTransfer(AccountId(101), -2)
            .transactionId(TestConstants.transactionId).nodeAccountIds(TestConstants.nodeAccountIds).freeze().sign(
                Self.firstPrivateKey
            )
            .sign(Self.secondPrivateKey)
            .toBytes()

        let tx2 = try Transaction.fromBytes(bodyBytes)

        XCTAssertEqual(try tx2.getSignatures().count, 2)
    }

    internal func test_GetAllSignaturesFromChunked() throws {
        let client = Client.forTestnet()
        client.setOperator(0, .generateEd25519())

        let transactionId = TransactionId(accountId: 0, validStart: .now)

        let tx = try TopicMessageSubmitTransaction()
            .topicId(314)
            .message("Meep!".data(using: .utf8)!)
            .chunkSize(8)
            .maxChunks(2)
            .transactionId(transactionId)
            .freezeWith(client)

        XCTAssertEqual(try tx.getAllSignatures().count, 1)
    }
}
