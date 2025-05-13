// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        /// Grab the environment variables.
        let env = try Dotenv.load()

        /// Initialize the client based on the provided environment.
        let client = try Client.forName(env.networkName)
        client.setOperator(env.operatorAccountId, env.operatorKey)

        /// Step 1: Create batch keys.
        let batchKey1 = PrivateKey.generateEcdsa()
        let batchKey2 = PrivateKey.generateEcdsa()
        let batchKey3 = PrivateKey.generateEcdsa()

        /// Step 2: Create accounts.
        let aliceKey = PrivateKey.generateEcdsa()
        let aliceAccountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(aliceKey.publicKey))
            .initialBalance(5)
            .execute(client)
            .getReceipt(client).accountId!
        print("Alice account ID: \(aliceAccountId)")

        let bobKey = PrivateKey.generateEcdsa()
        let bobAccountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(bobKey.publicKey))
            .initialBalance(5)
            .execute(client)
            .getReceipt(client).accountId!
        print("Bob account ID: \(bobAccountId)")

        let carolKey = PrivateKey.generateEcdsa()
        let carolAccountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(carolKey.publicKey))
            .initialBalance(5)
            .execute(client)
            .getReceipt(client).accountId!
        print("Carol account ID: \(carolAccountId)")

        /// Step 3: Prepare transfers for batching.
        let aliceTransferTx = try TransferTransaction()
            .hbarTransfer(env.operatorAccountId, Hbar(1))
            .hbarTransfer(aliceAccountId, Hbar(-1))
            .transactionId(TransactionId.generateFrom(aliceAccountId))
            .batchKey(.single(batchKey1.publicKey))
            .freezeWith(client)
            .sign(aliceKey)

        let bobTransferTx = try TransferTransaction()
            .hbarTransfer(env.operatorAccountId, Hbar(1))
            .hbarTransfer(bobAccountId, Hbar(-1))
            .transactionId(TransactionId.generateFrom(bobAccountId))
            .batchKey(.single(batchKey2.publicKey))
            .freezeWith(client)
            .sign(bobKey)

        let carolTransferTx = try TransferTransaction()
            .hbarTransfer(env.operatorAccountId, Hbar(1))
            .hbarTransfer(carolAccountId, Hbar(-1))
            .transactionId(TransactionId.generateFrom(carolAccountId))
            .batchKey(.single(batchKey3.publicKey))
            .freezeWith(client)
            .sign(carolKey)

        /// Step 4: Get initial balances.
        let aliceBalance = try await AccountBalanceQuery().accountId(aliceAccountId).execute(client)
        let bobBalance = try await AccountBalanceQuery().accountId(bobAccountId).execute(client)
        let carolBalance = try await AccountBalanceQuery().accountId(carolAccountId).execute(client)
        print("Alice balance: \(aliceBalance.hbars)")
        print("Bob balance: \(bobBalance.hbars)")
        print("Carol balance: \(carolBalance.hbars)")

        /// Step 5: Prepare and send the batch transaction.
        _ = try await BatchTransaction()
            .addInnerTransaction(aliceTransferTx)
            .addInnerTransaction(bobTransferTx)
            .addInnerTransaction(carolTransferTx)
            .freezeWith(client)
            .sign(batchKey1)
            .sign(batchKey2)
            .sign(batchKey3)
            .execute(client)
            .getReceipt(client)

        /// Step 6: Get and compare balances.
        let aliceNewBalance = try await AccountBalanceQuery().accountId(aliceAccountId).execute(client)
        let bobNewBalance = try await AccountBalanceQuery().accountId(bobAccountId).execute(client)
        let carolNewBalance = try await AccountBalanceQuery().accountId(carolAccountId).execute(client)
        print("Alice balance (should be 1 less): \(aliceNewBalance.hbars)")
        print("Bob balance (should be 1 less): \(bobNewBalance.hbars)")
        print("Carol balance (should be 1 less): \(carolNewBalance.hbars)")

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
