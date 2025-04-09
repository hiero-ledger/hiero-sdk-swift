// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        // generate a submit key to use with the topic.
        let submitKey = PrivateKey.generateEd25519()

        let topicId = try await TopicCreateTransaction()
            .topicMemo("sdk::swift::ConsensusPubSubChunked")
            .submitKey(.single(submitKey.publicKey))
            .execute(client)
            .getReceipt(client)
            .topicId!

        print("Created Topic `\(topicId)`")

        print("Waiting 10s for the mirror node to catch up")

        try await Task.sleep(nanoseconds: 1_000_000_000 * 10)

        _ = Task {
            let bigContents = try await HieroExampleUtilities.Resources.bigContents

            print(
                "about to prepare a transaction to send a message of \(bigContents.count) bytes"
            )

            // note: this used to set `maxChunks(15)` with a comment saying that the default is 10, but it's 20.
            // todo: sign with operator (once that's merged)
            let transaction = try TopicMessageSubmitTransaction()
                .topicId(topicId)
                .message(bigContents.data(using: .utf8)!)
                .freezeWith(client)
                .sign(env.operatorKey)

            // serialize to bytes so we can be signed "somewhere else" by the submit key
            let transactionBytes = try transaction.toBytes()

            // now pretend we sent those bytes across the network
            // parse them into a transaction so we can sign as the submit key
            let deserializedTransaction = try Transaction.fromBytes(transactionBytes)
            guard let topicMessageSubmitTransaction = deserializedTransaction as? TopicMessageSubmitTransaction else {
                fatalError("Expected TopicMessageSubmitTransaction")
            }
            // sign with that submit key
            topicMessageSubmitTransaction.sign(submitKey)

            // now actually submit the transaction
            // get the receipt to ensure there were no errors
            _ = try await topicMessageSubmitTransaction.execute(client).getReceipt(client)

            print("Finished sending the message, press ctrl+c to exit once it's recieved")
        }

        let stream = TopicMessageQuery()
            .topicId(topicId)
            .subscribe(client)

        // note: There's only going to be a single message recieved.
        for try await message in stream.prefix(1) {
            print(
                "(seq: `\(message.sequenceNumber)`, contents: `\(message.contents.count)` bytes) reached consensus at \(message.consensusTimestamp)"
            )
        }
    }
}
