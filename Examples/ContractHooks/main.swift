// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroProtobufs

@main
struct ContractHooksExample {
    static func main() async throws {
        // Initialize the client
        let client = Client.forTestnet()
        
        // Create operator account
        let operatorKey = PrivateKey.generateEd25519()
        let operatorId = try AccountId.fromString("0.0.1234") // Replace with your account ID
        
        client.setOperator(operatorId, operatorKey)
        
        print("🚀 Contract Hooks Example")
        print("========================")
        
        // Create a contract that will serve as our hook
        print("\n📝 Creating hook contract...")
        
        let hookContractKey = PrivateKey.generateEd25519()
        let hookContractResponse = try await ContractCreateTransaction()
            .bytecodeFileId(FileId.fromString("0.0.1235")) // Replace with your contract file ID
            .adminKey(.single(hookContractKey.publicKey))
            .gas(100000)
            .execute(client)
        let hookContractReceipt = try await hookContractResponse.getReceipt(client)
        let hookContractId = hookContractReceipt.contractId!
        
        print("✅ Created hook contract: \(hookContractId)")
        
        // Create Lambda EVM Hook specification
        print("\n🔧 Creating Lambda EVM Hook specification...")
        
        var evmHookSpec = EvmHookSpec()
        evmHookSpec = evmHookSpec.contractId(hookContractId)
        
        let lambdaEvmHook = LambdaEvmHook(spec: evmHookSpec)
        
        // Create hook creation details
        var hookCreationDetails = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        hookCreationDetails = hookCreationDetails.lambdaEvmHook(lambdaEvmHook)
        hookCreationDetails = hookCreationDetails.adminKey(Key.single(hookContractKey.publicKey))
        
        // Example 1: Create contract with hooks
        print("\n📄 Example 1: Creating contract with hooks")
        
        let contractKey = PrivateKey.generateEd25519()
        let contractResponse = try await ContractCreateTransaction()
            .bytecodeFileId(FileId.fromString("0.0.1236")) // Replace with your contract file ID
            .adminKey(.single(contractKey.publicKey))
            .gas(200000)
            .addHook(hookCreationDetails)
            .execute(client)
        let contractReceipt = try await contractResponse.getReceipt(client)
        let contractId = contractReceipt.contractId!
        
        print("✅ Created contract with hooks: \(contractId)")
        
        // Example 2: Update contract to add more hooks
        print("\n🔄 Example 2: Updating contract to add more hooks")
        
        var hookCreationDetails2 = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        hookCreationDetails2 = hookCreationDetails2.lambdaEvmHook(lambdaEvmHook)
        hookCreationDetails2 = hookCreationDetails2.adminKey(Key.single(hookContractKey.publicKey))
        
        let updateResponse = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToCreate(hookCreationDetails2)
            .execute(client)
        let updateReceipt = try await updateResponse.getReceipt(client)
        
        print("✅ Updated contract with additional hooks: \(updateReceipt.status)")
        
        // Example 3: Update contract to delete hooks
        print("\n🗑️ Example 3: Updating contract to delete hooks")
        
        let deleteResponse = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToDelete(1) // Delete hook with ID 1
            .execute(client)
        let deleteReceipt = try await deleteResponse.getReceipt(client)
        
        print("✅ Updated contract to delete hooks: \(deleteReceipt.status)")
        
        // Example 4: Execute contract with hooks
        print("\n⚡ Example 4: Executing contract with hooks")
        
        let executeResponse = try await ContractExecuteTransaction()
            .contractId(contractId)
            .gas(100000)
            .function("someFunction")
            .execute(client)
        let executeReceipt = try await executeResponse.getReceipt(client)
        
        print("✅ Executed contract with hooks: \(executeReceipt.status)")
        
        // Cleanup
        print("\n🧹 Cleaning up...")
        
        _ = try await ContractDeleteTransaction()
            .contractId(contractId)
            .transferAccountId(operatorId)
            .execute(client)
            .getReceipt(client)
        
        _ = try await ContractDeleteTransaction()
            .contractId(hookContractId)
            .transferAccountId(operatorId)
            .execute(client)
            .getReceipt(client)
        
        print("✅ Cleanup completed")
        print("\n🎉 Contract Hooks Example completed successfully!")
    }
}
