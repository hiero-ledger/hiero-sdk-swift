// SPDX-License-Identifier: Apache-2.0

import Hiero
import SwiftDotenv

/// Example demonstrating high-volume account creation using HIP-1313.
///
/// HIP-1313 introduces a second set of throttles for entity creation that sit alongside
/// the existing standard throttles. Users can opt into these high-volume throttles by
/// setting the `highVolume` flag on their transactions, accepting dynamic pricing during
/// busy periods to access additional capacity.
///
/// ## Key Points:
/// - High-volume throttles provide additional capacity for entity creation
/// - Pricing is dynamic based on throttle utilization (higher usage = higher fees)
/// - Always set `maxTransactionFee` when using high-volume to control costs
/// - Standard throttles remain unchanged for users who don't opt in
/// - Transactions are processed in arrival order (no priority for high-volume)
///
/// ## Supported Transaction Types:
/// - `TopicCreateTransaction`
/// - `ContractCreateTransaction`
/// - `AccountAllowanceApproveTransaction`
/// - `AccountCreateTransaction`
/// - `TransferTransaction` (for hollow account creation)
/// - `FileCreateTransaction`
/// - `FileAppendTransaction`
/// - `LambdaSStoreTransaction`
/// - `ScheduleCreateTransaction`
/// - `TokenAirdropTransaction`
/// - `TokenAssociateTransaction`
/// - `TokenCreateTransaction`
/// - `TokenClaimAirdropTransaction`
/// - `TokenMintTransaction`
///
/// For more information, see: https://hips.hedera.com/hip/hip-1313

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Generate a new key for the account
        let newAccountKey = PrivateKey.generateEd25519()

        print("Creating account using high-volume throttles...")
        print("Private key: \(newAccountKey)")
        print("Public key: \(newAccountKey.publicKey)")

        // Create an account using high-volume throttles
        // Important: Always set maxTransactionFee when using high-volume
        // to control costs during peak utilization
        let response = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newAccountKey.publicKey))
            .initialBalance(Hbar(10))
            .highVolume(true)  // Enable high-volume throttles (HIP-1313)
            .maxTransactionFee(Hbar(5))  // Set a fee limit to control costs
            .execute(client)

        let receipt = try await response.getReceipt(client)
        let newAccountId = receipt.accountId!

        print("Account created successfully!")
        print("Account ID: \(newAccountId)")

        // Verify the account was created
        let info = try await AccountInfoQuery()
            .accountId(newAccountId)
            .execute(client)

        print("\nAccount Info:")
        print("  Account ID: \(info.accountId)")
        print("  Balance: \(info.balance)")
        print("  Key: \(info.key)")

        print("\nHigh-volume account creation example completed successfully!")
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
