// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        // Set operator account
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Step 1: Create Alice's account
        print("Creating Alice's account...")
        let aliceKey = PrivateKey.generateEcdsa()

        let aliceAccountReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(Key.single(aliceKey.publicKey))
            .maxAutomaticTokenAssociations(1)
            .initialBalance(Hbar(2))
            .execute(client)
            .getReceipt(client)

        let aliceAccountId = aliceAccountReceipt.accountId!
        print("Alice's Account ID: \(aliceAccountId)")

        // Step 2: Create topic with HBAR custom fee
        print("Creating a topic with HBAR custom fee...")
        let customFee = CustomFixedFee(UInt64(Hbar(1).toTinybars()), env.operatorAccountId)

        let topicReceipt = try await TopicCreateTransaction()
            .adminKey(.single(env.operatorKey.publicKey))
            .feeScheduleKey(.single(env.operatorKey.publicKey))
            .addCustomFee(customFee)
            .execute(client)
            .getReceipt(client)

        let topicId = topicReceipt.topicId!
        print("Created Topic ID: \(topicId)")

        // Step 3: Submit message as Alice with custom fee limit
        print("Submitting a message as Alice to the topic...")

        let aliceBalanceBefore = try await AccountBalanceQuery()
            .accountId(aliceAccountId)
            .execute(client)
            .hbars

        let feeCollectorBalanceBefore = try await AccountBalanceQuery()
            .accountId(env.operatorAccountId)
            .execute(client)
            .hbars

        let customFeeLimit = CustomFeeLimit(
            payerId: aliceAccountId,
            customFees: [CustomFixedFee(UInt64(Hbar(2).toTinybars()), env.operatorAccountId)]
        )

        client.setOperator(aliceAccountId, aliceKey)

        _ = try await TopicMessageSubmitTransaction()
            .customFeeLimits([customFeeLimit])
            .topicId(topicId)
            .message(Data("Hello, Hedera™ hashgraph!".utf8))
            .execute(client)
            .getReceipt(client)

        print("Message submitted successfully.")

        // Step 4: Verify Alice's and fee collector's balance after the transaction.
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Check balances
        let aliceBalanceAfter = try await AccountBalanceQuery()
            .accountId(aliceAccountId)
            .execute(client)
            .hbars

        let feeCollectorBalanceAfter = try await AccountBalanceQuery()
            .accountId(env.operatorAccountId)
            .execute(client)
            .hbars

        print("Alice's balance before: \(aliceBalanceBefore), after: \(aliceBalanceAfter)")
        print("Fee collector's balance before: \(feeCollectorBalanceBefore), after: \(feeCollectorBalanceAfter)")

        // Step 5: Create a fungible token and transfer it to Alice.
        print("Creating a token and transferring it to Alice...")

        let tokenReceipt = try await TokenCreateTransaction()
            .name("revenue-generating token")
            .symbol("RGT")
            .treasuryAccountId(env.operatorAccountId)
            .decimals(8)
            .initialSupply(100)
            .execute(client)
            .getReceipt(client)

        let tokenId = tokenReceipt.tokenId!

        _ = try await TransferTransaction()
            .tokenTransfer(tokenId, env.operatorAccountId, -1)
            .tokenTransfer(tokenId, aliceAccountId, 1)
            .execute(client)
            .getReceipt(client)

        // Step 6: Update the topic to charge a token-based fee.
        print("Updating the topic to charge a token-based fee...")
        let tokenFee = CustomFixedFee(1, env.operatorAccountId, tokenId)

        _ = try await TopicUpdateTransaction()
            .topicId(topicId)
            .customFees([tokenFee])
            .execute(client)
            .getReceipt(client)

        // Step 7: Submit another message without specifying a custom fee limit.
        client.setOperator(aliceAccountId, aliceKey)

        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Another message!".utf8))
            .execute(client)
            .getReceipt(client)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Step 8: Verify Alice's token balance and the fee collector's token balance after the transaction.
        let aliceTokenBalance = try await AccountBalanceQuery()
            .accountId(aliceAccountId)
            .execute(client)
            .tokenBalances[tokenId]!

        let feeCollectorTokenBalance = try await AccountBalanceQuery()
            .accountId(env.operatorAccountId)
            .execute(client)
            .tokenBalances[tokenId]!

        print("Alice's token balance: \(String(describing: aliceTokenBalance))")
        print("Fee collector's token balance: \(String(describing: feeCollectorTokenBalance))")

        // Step 9: Create Bob's account with 10 hbar
        print("Creating Bob's account...")
        let bobKey = PrivateKey.generateEcdsa()

        let bobAccountReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(Key.single(bobKey.publicKey))
            .initialBalance(Hbar(10))
            .maxAutomaticTokenAssociations(100)
            .execute(client)
            .getReceipt(client)

        let bobAccountId = bobAccountReceipt.accountId!
        print("Bob's Account ID: \(bobAccountId)")

        // Step 10: Exempt Bob from paying topic fees.
        print("Updating topic to add Bob as a fee-exempt key...")

        _ = try await TopicUpdateTransaction()
            .topicId(topicId)
            .addFeeExemptKey(.single(bobKey.publicKey))
            .execute(client)
            .getReceipt(client)

        // Step 11: Submit a message as Bob without being charged.
        client.setOperator(bobAccountId, bobKey)

        _ = try await TopicMessageSubmitTransaction()
            .topicId(topicId)
            .message(Data("Hello from Bob!".utf8))
            .execute(client)
            .getReceipt(client)

        print("Message submitted successfully by Bob without being charged.")

        // Step 12: Verify Bob's balance after the transaction.
        let bobBalanceAfter = try await AccountBalanceQuery()
            .accountId(bobAccountId)
            .execute(client)
            .hbars

        print("Bob's final balance: \(bobBalanceAfter)")
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
