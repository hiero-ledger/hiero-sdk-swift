// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities
import SwiftDotenv
import Foundation

@main
internal enum Program {
    internal static func main() async throws {
        /// Grab the environment variables.
        let env = try Dotenv.load()

        /// Initialize the client based on the provided environment.
        let client = try Client.forName(env.networkName)
        client.setOperator(env.operatorAccountId, env.operatorKey)
        
        print("Account Hooks Example")
        print("====================")
        
        // Create a contract that will serve as our hook
        print("Creating hook contract...")
        
        let contractKey = PrivateKey.generateEd25519()
        let contractResponse = try await ContractCreateTransaction()
            .bytecode(Data(hexEncoded: "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033")!)
            .adminKey(.single(contractKey.publicKey))
            .gas(100000)
            .execute(client)
        let contractReceipt = try await contractResponse.getReceipt(client)
        let contractId = contractReceipt.contractId!
        
        print("Created hook contract: \(contractId)")
        
        // Create Lambda EVM Hook specification
        print("Creating Lambda EVM Hook specification...")
        
        var evmHookSpec = EvmHookSpec()
        evmHookSpec = evmHookSpec.contractId(contractId)
        
        let lambdaEvmHook = LambdaEvmHook(spec: evmHookSpec)
        
        // Create hook creation details
        var hookCreationDetails = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        hookCreationDetails = hookCreationDetails.lambdaEvmHook(lambdaEvmHook)
        hookCreationDetails = hookCreationDetails.adminKey(Key.single(contractKey.publicKey))
        
        // Example 1: Create account with hooks
        print("Example 1: Creating account with hooks")
        
        let accountKey = PrivateKey.generateEd25519()
        let accountResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))
            .initialBalance(10)
            .addHook(hookCreationDetails)
            .execute(client)
        let accountReceipt = try await accountResponse.getReceipt(client)
        let accountId = accountReceipt.accountId!
        
        print("Created account with hooks: \(accountId)")
        
        // Example 2: Update account to add more hooks
        print("Example 2: Updating account to add more hooks")
        
        var hookCreationDetails2 = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        hookCreationDetails2 = hookCreationDetails2.lambdaEvmHook(lambdaEvmHook)
        hookCreationDetails2 = hookCreationDetails2.adminKey(Key.single(contractKey.publicKey))
        
        let updateResponse = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToCreate(hookCreationDetails2)
            .execute(client)
        let updateReceipt = try await updateResponse.getReceipt(client)
        
        print("Updated account with additional hooks: \(updateReceipt.status)")
        
        // Example 3: Update account to delete hooks
        print("Example 3: Updating account to delete hooks")
        
        let deleteResponse = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToDelete(1) // Delete hook with ID 1
            .execute(client)
        let deleteReceipt = try await deleteResponse.getReceipt(client)
        
        print("Updated account to delete hooks: \(deleteReceipt.status)")
        
        // Cleanup
        print("Cleaning up...")
        
        _ = try await AccountDeleteTransaction()
            .accountId(accountId)
            .transferAccountId(env.operatorAccountId)
            .execute(client)
            .getReceipt(client)
        
        _ = try await ContractDeleteTransaction()
            .contractId(contractId)
            .transferAccountId(env.operatorAccountId)
            .execute(client)
            .getReceipt(client)
        
        print("Cleanup completed")
        print("\nAccount Hooks Example completed successfully!")
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

    /// The name of the Hiero network this example should run against.
    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
