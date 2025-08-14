// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        // Defaults the operator account ID and key such that all generated transactions will be paid for
        // by this account and be signed by this key
        client.setOperator(env.operatorAccountId, env.operatorKey)

        let key = PrivateKey.generateEd25519()
        let accountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .execute(client)
            .getReceipt(client)
            .accountId!

        // Generate a Ed25519 private, public key pair
        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()

        print("private key 1 = \(key1)")
        print("public key 1 = \(key1.publicKey)")
        print("private key 2 = \(key2)")
        print("public key 2 = \(key2.publicKey)")

        var customFee = CustomFixedFee()
        customFee.feeCollectorAccountId = accountId
        customFee.amount = 10

        let topicId = try await TopicCreateTransaction()
            .feeScheduleKey(.single(key1.publicKey))
            .addCustomFee(customFee)
            .execute(client)
            .getReceipt(client)
            .topicId!

        print("new topic ID: \(topicId)")

        var customFeeLimitFee = CustomFixedFee()
        customFeeLimitFee.amount = 5
        let customFeeLimit = CustomFeeLimit(payerId: env.operatorAccountId, customFees: [customFeeLimitFee])

        let response = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message("hello from hashgraph".data(using: .utf8)!)
            .addCustomFeeLimit(customFeeLimit)
            .schedule()
            .expirationTime(.now + .seconds(3))
            .isWaitForExpiry(true)
            .execute(client)

        let scheduledTransactionId = response.transactionId
        print("scheduled transaction ID = \(scheduledTransactionId)")

        let scheduleId = try await response.getReceipt(client).scheduleId!
        print("schedule ID = \(scheduleId)")

        _ = try await Task.sleep(nanoseconds: 1_000_000_000 * 6)

        let scheduleInfo = try await ScheduleInfoQuery().scheduleId(scheduleId).execute(client)

        print("scheduleInfo = \(scheduleInfo)")

        print("scheduled transaction receipt = \(try await TransactionReceiptQuery().transactionId(scheduledTransactionId).execute(client))")
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
