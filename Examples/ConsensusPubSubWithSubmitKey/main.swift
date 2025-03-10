// SPDX-License-Identifier: Apache-2.0

import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        // generate a submit key to use with the topic.
        let submitKey = PrivateKey.generateEd25519()

        let topicId = try await TopicCreateTransaction()
            .topicMemo("sdk::swift::ConsensusPubSubWithSubmitKey")
            .submitKey(.single(submitKey.publicKey))
            .execute(client)
            .getReceipt(client)
            .topicId!

        print("Created Topic `\(topicId)`")

        print("Waiting 10s for the mirror node to catch up")

        try await Task.sleep(nanoseconds: 1_000_000_000 * 10)

        _ = Task {
            print("sending 5 messages")

            for i in 0..<5 {
                let v = Int64.random(in: .min...Int64.max)
                let message = "random message: \(v)"

                print("publishing message \(i): `\(message)`")

                _ = try await TopicMessageSubmitTransaction()
                    .topicId(topicId)
                    .message(message.data(using: .utf8)!)
                    .sign(submitKey)
                    .execute(client)
                    .getReceipt(client)

                try await Task.sleep(nanoseconds: 1_000_000_000 * 2)
            }

            print("Finished sending the message, press ctrl+c to exit once it's recieved")
        }

        let stream = TopicMessageQuery()
            .topicId(topicId)
            .subscribe(client)

        // note: There's only going to be a single message recieved.
        for try await message in stream.prefix(5) {
            print(
                "(seq: `\(message.sequenceNumber)`, contents: `\(String(data: message.contents, encoding: .utf8)!)` reached consensus at \(message.consensusTimestamp)"
            )
        }
    }
}

extension Environment {
    /// Account ID for the operator to use in this example.
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    /// Private key for the operator to use in this example.
    internal var operatorKey: PrivateKey {
        PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
    }

    /// The name of the hedera network this example should be ran against.
    ///
    /// Testnet by default.
    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
