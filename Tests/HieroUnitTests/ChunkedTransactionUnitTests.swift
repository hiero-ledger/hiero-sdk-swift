// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ChunkedTransactionUnitTests: HieroUnitTestCase {
    internal func test_ToFromBytes() throws {
        let client = Client.forTestnet()
        client.setOperator(0, .generateEd25519())

        let transactionId = TransactionId(accountId: 0, validStart: .now)

        let bytes = try TopicMessageSubmitTransaction()
            .topicId(314)
            .message("Hello, world!".data(using: .utf8)!)
            .chunkSize(8)
            .maxChunks(2)
            .transactionId(transactionId)
            .freezeWith(client)
            .toBytes()

        let transaction = try Transaction.fromBytes(bytes)

        guard let transaction = transaction as? TopicMessageSubmitTransaction else {
            XCTFail("Transaction wasn't a TopicMessageSubmitTransaction (it was actually \(type(of: transaction))")
            return
        }

        XCTAssertEqual(transaction.topicId, 314)
        XCTAssertEqual(transaction.message, "Hello, world!".data(using: .utf8)!)
        XCTAssertEqual(transaction.transactionId, transactionId)
    }

    // MARK: - Cross-group forgery rejection tests

    /// Non-chunked types (e.g. CryptoTransfer) with multiple TransactionId groups must be rejected,
    /// even when the bodies are identical across groups.
    internal func test_fromBytes_rejectMultiGroupNonChunked() throws {
        let txId1 = TransactionId.withValidStart(
            AccountId(num: 100), Timestamp(seconds: 1_554_158_542, subSecondNanos: 0))
        let txId2 = TransactionId.withValidStart(
            AccountId(num: 100), Timestamp(seconds: 1_554_158_543, subSecondNanos: 0))

        let transfer = Proto_CryptoTransferTransactionBody.with { proto in
            proto.transfers = Proto_TransferList.with { list in
                list.accountAmounts = [
                    Proto_AccountAmount.with { amt in
                        amt.accountID = AccountId(num: 100).toProtobuf()
                        amt.amount = -100
                    },
                    Proto_AccountAmount.with { amt in
                        amt.accountID = AccountId(num: 200).toProtobuf()
                        amt.amount = 100
                    },
                ]
            }
        }

        let tx1 = try makeSignedTx(txId: txId1) { $0.cryptoTransfer = transfer }
        let tx2 = try makeSignedTx(txId: txId2) { $0.cryptoTransfer = transfer }

        var list = Proto_TransactionList()
        list.transactionList = [tx1, tx2]
        let bytes = try list.serializedData()

        XCTAssertThrowsError(try Transaction.fromBytes(bytes))
    }

    /// A consensusSubmitMessage list with 2 actual groups but chunkInfo.total = 1 must be rejected.
    internal func test_fromBytes_rejectChunkCountMismatch_totalTooLow() throws {
        let txId1 = TransactionId.withValidStart(
            AccountId(num: 100), Timestamp(seconds: 1_554_158_542, subSecondNanos: 0))
        let txId2 = TransactionId.withValidStart(
            AccountId(num: 100), Timestamp(seconds: 1_554_158_543, subSecondNanos: 0))
        let topicId = TopicId(num: 1)

        // Both groups declare total=1, but there are 2 actual groups.
        let tx1 = try makeSignedTx(txId: txId1) { body in
            body.consensusSubmitMessage = Proto_ConsensusSubmitMessageTransactionBody.with { proto in
                proto.topicID = topicId.toProtobuf()
                proto.message = Data("chunk1".utf8)
                proto.chunkInfo = Proto_ConsensusMessageChunkInfo.with { info in
                    info.initialTransactionID = txId1.toProtobuf()
                    info.total = 1
                    info.number = 1
                }
            }
        }
        let tx2 = try makeSignedTx(txId: txId2) { body in
            body.consensusSubmitMessage = Proto_ConsensusSubmitMessageTransactionBody.with { proto in
                proto.topicID = topicId.toProtobuf()
                proto.message = Data("chunk2".utf8)
                proto.chunkInfo = Proto_ConsensusMessageChunkInfo.with { info in
                    info.initialTransactionID = txId1.toProtobuf()
                    info.total = 1
                    info.number = 1
                }
            }
        }

        var list = Proto_TransactionList()
        list.transactionList = [tx1, tx2]
        let bytes = try list.serializedData()

        XCTAssertThrowsError(try Transaction.fromBytes(bytes))
    }

    /// A consensusSubmitMessage list with 2 actual groups but chunkInfo.total = 3 must be rejected.
    internal func test_fromBytes_rejectChunkCountMismatch_totalTooHigh() throws {
        let txId1 = TransactionId.withValidStart(
            AccountId(num: 100), Timestamp(seconds: 1_554_158_542, subSecondNanos: 0))
        let txId2 = TransactionId.withValidStart(
            AccountId(num: 100), Timestamp(seconds: 1_554_158_543, subSecondNanos: 0))
        let topicId = TopicId(num: 1)

        // Both groups declare total=3, but there are only 2 actual groups.
        let tx1 = try makeSignedTx(txId: txId1) { body in
            body.consensusSubmitMessage = Proto_ConsensusSubmitMessageTransactionBody.with { proto in
                proto.topicID = topicId.toProtobuf()
                proto.message = Data("chunk1".utf8)
                proto.chunkInfo = Proto_ConsensusMessageChunkInfo.with { info in
                    info.initialTransactionID = txId1.toProtobuf()
                    info.total = 3
                    info.number = 1
                }
            }
        }
        let tx2 = try makeSignedTx(txId: txId2) { body in
            body.consensusSubmitMessage = Proto_ConsensusSubmitMessageTransactionBody.with { proto in
                proto.topicID = topicId.toProtobuf()
                proto.message = Data("chunk2".utf8)
                proto.chunkInfo = Proto_ConsensusMessageChunkInfo.with { info in
                    info.initialTransactionID = txId1.toProtobuf()
                    info.total = 3
                    info.number = 2
                }
            }
        }

        var list = Proto_TransactionList()
        list.transactionList = [tx1, tx2]
        let bytes = try list.serializedData()

        XCTAssertThrowsError(try Transaction.fromBytes(bytes))
    }

    /// A consensusSubmitMessage list with swapped chunk numbers must be rejected.
    internal func test_fromBytes_rejectOutOfOrderChunkNumbers() throws {
        let txId1 = TransactionId.withValidStart(
            AccountId(num: 100), Timestamp(seconds: 1_554_158_542, subSecondNanos: 0))
        let txId2 = TransactionId.withValidStart(
            AccountId(num: 100), Timestamp(seconds: 1_554_158_543, subSecondNanos: 0))
        let topicId = TopicId(num: 1)

        // Group appearing first declares number=2; group appearing second declares number=1.
        let tx1 = try makeSignedTx(txId: txId1) { body in
            body.consensusSubmitMessage = Proto_ConsensusSubmitMessageTransactionBody.with { proto in
                proto.topicID = topicId.toProtobuf()
                proto.message = Data("chunk2".utf8)
                proto.chunkInfo = Proto_ConsensusMessageChunkInfo.with { info in
                    info.initialTransactionID = txId1.toProtobuf()
                    info.total = 2
                    info.number = 2
                }
            }
        }
        let tx2 = try makeSignedTx(txId: txId2) { body in
            body.consensusSubmitMessage = Proto_ConsensusSubmitMessageTransactionBody.with { proto in
                proto.topicID = topicId.toProtobuf()
                proto.message = Data("chunk1".utf8)
                proto.chunkInfo = Proto_ConsensusMessageChunkInfo.with { info in
                    info.initialTransactionID = txId1.toProtobuf()
                    info.total = 2
                    info.number = 1
                }
            }
        }

        var list = Proto_TransactionList()
        list.transactionList = [tx1, tx2]
        let bytes = try list.serializedData()

        XCTAssertThrowsError(try Transaction.fromBytes(bytes))
    }

    // MARK: - Helpers

    private func makeSignedTx(
        txId: TransactionId,
        nodeId: AccountId = AccountId(num: 3),
        configure: (inout Proto_TransactionBody) -> Void
    ) throws -> Proto_Transaction {
        var body = Proto_TransactionBody()
        body.transactionID = txId.toProtobuf()
        body.nodeAccountID = nodeId.toProtobuf()
        configure(&body)

        var signedTx = Proto_SignedTransaction()
        signedTx.bodyBytes = try body.serializedData()

        var tx = Proto_Transaction()
        tx.signedTransactionBytes = try signedTx.serializedData()
        return tx
    }
}
