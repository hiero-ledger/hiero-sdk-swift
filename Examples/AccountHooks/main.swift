// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroProtobufs

@main
struct AccountHooksExample {
    static func main() async throws {
        // Initialize the client
        let client = Client.forTestnet()
        
        // Create operator account
        let operatorKey = PrivateKey.generateEd25519()
        let operatorId = try AccountId.fromString("0.0.1234") // Replace with your account ID
        
        client.setOperator(operatorId, operatorKey)
        
        print("🚀 Account Hooks Example")
        print("=======================")
        
        // Create a contract that will serve as our hook
        print("\n📝 Creating hook contract...")
        
        let contractKey = PrivateKey.generateEd25519()
        let contractResponse = try await ContractCreateTransaction()
            .bytecodeFileId(FileId.fromString("0.0.1235")) // Replace with your contract file ID
            .adminKey(.single(contractKey.publicKey))
            .gas(100000)
            .execute(client)
        let contractReceipt = try await contractResponse.getReceipt(client)
        let contractId = contractReceipt.contractId!
        
        print("✅ Created hook contract: \(contractId)")
        
        // Create Lambda EVM Hook specification
        print("\n🔧 Creating Lambda EVM Hook specification...")
        
        var evmHookSpec = EvmHookSpec()
        evmHookSpec = evmHookSpec.contractId(contractId)
        
        let lambdaEvmHook = LambdaEvmHook(spec: evmHookSpec)
        
        // Create hook creation details
        var hookCreationDetails = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        hookCreationDetails = hookCreationDetails.lambdaEvmHook(lambdaEvmHook)
        hookCreationDetails = hookCreationDetails.adminKey(Key.single(contractKey.publicKey))
        
        // Example 1: Create account with hooks
        print("\n👤 Example 1: Creating account with hooks")
        
        let accountKey = PrivateKey.generateEd25519()
        let accountResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))
            .initialBalance(10)
            .addHook(hookCreationDetails)
            .execute(client)
        let accountReceipt = try await accountResponse.getReceipt(client)
        let accountId = accountReceipt.accountId!
        
        print("✅ Created account with hooks: \(accountId)")
        
        // Example 2: Update account to add more hooks
        print("\n🔄 Example 2: Updating account to add more hooks")
        
        var hookCreationDetails2 = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        hookCreationDetails2 = hookCreationDetails2.lambdaEvmHook(lambdaEvmHook)
        hookCreationDetails2 = hookCreationDetails2.adminKey(Key.single(contractKey.publicKey))
        
        let updateResponse = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToCreate(hookCreationDetails2)
            .execute(client)
        let updateReceipt = try await updateResponse.getReceipt(client)
        
        print("✅ Updated account with additional hooks: \(updateReceipt.status)")
        
        // Example 3: Update account to delete hooks
        print("\n🗑️ Example 3: Updating account to delete hooks")
        
        let deleteResponse = try await AccountUpdateTransaction()
            .accountId(accountId)
            .addHookToDelete(1) // Delete hook with ID 1
            .execute(client)
        let deleteReceipt = try await deleteResponse.getReceipt(client)
        
        print("✅ Updated account to delete hooks: \(deleteReceipt.status)")
        
        // Cleanup
        print("\n🧹 Cleaning up...")
        
        _ = try await AccountDeleteTransaction()
            .accountId(accountId)
            .transferAccountId(operatorId)
            .execute(client)
            .getReceipt(client)
        
        _ = try await ContractDeleteTransaction()
            .contractId(contractId)
            .transferAccountId(operatorId)
            .execute(client)
            .getReceipt(client)
        
        print("✅ Cleanup completed")
        print("\n🎉 Account Hooks Example completed successfully!")
    }
}
