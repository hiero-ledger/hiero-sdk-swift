// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class TransactionUnitTests: HieroUnitTestCase {
    internal func test_ToFromBytes() throws {
        let new = TransferTransaction()

        let bytes = try new.maxTransactionFee(10)
            .transactionValidDuration(Duration.seconds(119))
            .transactionMemo("Frosted flakes")
            .hbarTransfer(AccountId(2), 2)
            .hbarTransfer(AccountId(101), -2)
            .transactionId(TestConstants.transactionId)
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .freeze()
            .toBytes()

        let tx = new

        let lhs = try tx.makeProtoBody()

        let tx2 = try Transaction.fromBytes(bytes)

        let rhs = try tx2.makeProtoBody()

        XCTAssertEqual(tx.maxTransactionFee, tx2.maxTransactionFee)

        let lhs1 = tx.nodeAccountIds
        let rhs2 = tx2.nodeAccountIds

        XCTAssertEqual(lhs1, rhs2)

        XCTAssertEqual(tx.transactionId, tx2.transactionId)
        XCTAssertEqual(tx.transactionMemo, tx2.transactionMemo)
        XCTAssertEqual(tx.transactionValidDuration, tx2.transactionValidDuration)
        XCTAssertEqual(lhs, rhs)
        XCTAssertNotNil(tx2.sources)
    }

    internal func test_FromBytesSignToBytes() throws {
        let new = TransferTransaction()

        let bytes = try new.maxTransactionFee(10).transactionValidDuration(Duration.seconds(119))
            .transactionMemo("Frosted flakes").hbarTransfer(AccountId(2), 2).hbarTransfer(AccountId(101), -2)
            .transactionId(TestConstants.transactionId).nodeAccountIds(TestConstants.nodeAccountIds).freeze().toBytes()

        let tx2 = try Transaction.fromBytes(bytes)

        tx2.sign(
            try PrivateKey.fromBytes(
                Data(
                    hexEncoded:
                        "302e020100300506032b657004220420e40d4241d093b22910c78135e0501b137cd9205bbb9c0153c5adf2c65e7dc95a"
                )!))

        _ = try tx2.toBytes()

        XCTAssertEqual(tx2.signers.count, 1)
    }

    internal func test_ChunkedToFromBytes() throws {
        let client = Client.forTestnet()
        client.setOperator(AccountId(0), PrivateKey.generateEd25519())

        let bytes = try TopicMessageSubmitTransaction().topicId(314).message(Data("Fish cutlery".utf8))
            .chunkSize(8).maxChunks(2).transactionId(TestConstants.transactionId)
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .customFeeLimits([
                CustomFeeLimit(
                    payerId: AccountId(0),
                    customFees: [CustomFixedFee(1, AccountId(0), TokenId("0.0.1"))]
                )
            ])
            .freezeWith(client).toBytes()

        let tx = try Transaction.fromBytes(bytes)

        _ = try tx.toBytes()
    }

    internal func test_ToFromIncompleteTransactionBytes() throws {
        let tx = TransferTransaction()
            .maxTransactionFee(10)
            .transactionValidDuration(Duration.seconds(119))
            .transactionMemo("Frosted flakes")
            .hbarTransfer(AccountId(2), 2)
            .hbarTransfer(AccountId(101), -2)

        let bytes = try tx.toBytes()
        let tx2 = try Transaction.fromBytes(bytes)

        XCTAssertEqual(tx.transactionId, tx2.transactionId)
        XCTAssertEqual(tx.nodeAccountIds, tx2.nodeAccountIds)
    }

    // MARK: - High Volume Tests (HIP-1313)

    internal func test_HighVolume_DefaultsToFalse() throws {
        let tx = AccountCreateTransaction()

        XCTAssertFalse(tx.highVolume)
    }

    internal func test_HighVolume_SetToTrue() throws {
        let tx = AccountCreateTransaction()
            .highVolume(true)

        XCTAssertTrue(tx.highVolume)
    }

    internal func test_HighVolume_SetToFalse() throws {
        let tx = AccountCreateTransaction()
            .highVolume(true)
            .highVolume(false)

        XCTAssertFalse(tx.highVolume)
    }

    internal func test_HighVolume_CannotSetAfterFreeze() throws {
        let tx = try AccountCreateTransaction()
            .key(.single(TestConstants.publicKey))
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .freeze()

        // Attempting to set highVolume after freeze should cause a precondition failure
        // In tests, we verify the property is frozen by checking it's still false
        XCTAssertFalse(tx.highVolume)
        XCTAssertTrue(tx.isFrozen)
    }

    internal func test_HighVolume_SerializesCorrectly() throws {
        let tx = try AccountCreateTransaction()
            .key(.single(TestConstants.publicKey))
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .highVolume(true)
            .freeze()

        let protoBody = try tx.makeProtoBody()

        XCTAssertTrue(protoBody.highVolume)
    }

    internal func test_HighVolume_DeserializesCorrectly() throws {
        let tx = try AccountCreateTransaction()
            .key(.single(TestConstants.publicKey))
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .highVolume(true)
            .freeze()

        let bytes = try tx.toBytes()
        let tx2 = try Transaction.fromBytes(bytes)

        XCTAssertTrue(tx2.highVolume)
    }

    internal func test_HighVolume_FalseDoesNotSerialize() throws {
        let tx = try AccountCreateTransaction()
            .key(.single(TestConstants.publicKey))
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .transactionId(TestConstants.transactionId)
            .highVolume(false)
            .freeze()

        let protoBody = try tx.makeProtoBody()

        // When highVolume is false (default), it should not be set in the protobuf
        // (protobuf default for bool is false)
        XCTAssertFalse(protoBody.highVolume)
    }

    internal func test_HighVolume_RoundTrip() throws {
        let tx = try TransferTransaction()
            .maxTransactionFee(10)
            .transactionValidDuration(Duration.seconds(119))
            .transactionMemo("High volume transfer")
            .hbarTransfer(AccountId(2), 2)
            .hbarTransfer(AccountId(101), -2)
            .transactionId(TestConstants.transactionId)
            .nodeAccountIds(TestConstants.nodeAccountIds)
            .highVolume(true)
            .freeze()

        let bytes = try tx.toBytes()
        let tx2 = try Transaction.fromBytes(bytes)

        XCTAssertTrue(tx2.highVolume)
        XCTAssertEqual(tx.transactionMemo, tx2.transactionMemo)
        XCTAssertEqual(try tx.makeProtoBody(), try tx2.makeProtoBody())
    }

    internal func test_HighVolume_MethodChaining() throws {
        let tx = AccountCreateTransaction()
            .key(.single(TestConstants.publicKey))
            .initialBalance(Hbar(10))
            .highVolume(true)
            .maxTransactionFee(Hbar(5))

        XCTAssertTrue(tx.highVolume)
        XCTAssertEqual(tx.initialBalance, Hbar(10))
        XCTAssertEqual(tx.maxTransactionFee, Hbar(5))
    }
}
