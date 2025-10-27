// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroProtobufs

@main
struct LambdaSStoreExample {
    static func main() async throws {
        // Initialize the client
        let client = Client.forTestnet()
        
        // Create operator account
        let operatorKey = PrivateKey.generateEd25519()
        let operatorId = try AccountId.fromString("0.0.1234") // Replace with your account ID
        
        client.setOperator(operatorId, operatorKey)
        
        print("🚀 Lambda SSTORE Example")
        print("========================")
        
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
        
        // Create account with hooks
        print("\n👤 Creating account with hooks...")
        
        var evmHookSpec = EvmHookSpec()
        evmHookSpec = evmHookSpec.contractId(contractId)
        
        let lambdaEvmHook = LambdaEvmHook(spec: evmHookSpec)
        
        var hookCreationDetails = HookCreationDetails(hookExtensionPoint: .accountAllowanceHook)
        hookCreationDetails = hookCreationDetails.lambdaEvmHook(lambdaEvmHook)
        hookCreationDetails = hookCreationDetails.adminKey(Key.single(contractKey.publicKey))
        
        let accountKey = PrivateKey.generateEd25519()
        let accountResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))
            .initialBalance(10)
            .addHook(hookCreationDetails)
            .execute(client)
        let accountReceipt = try await accountResponse.getReceipt(client)
        let accountId = accountReceipt.accountId!
        
        print("✅ Created account with hooks: \(accountId)")
        
        // Create HookId for the Lambda SSTORE transaction
        print("\n🔧 Creating HookId...")
        
        var hookEntityId = HookEntityId()
        hookEntityId = hookEntityId.accountId(accountId)
        
        let hookId = HookId(entityId: hookEntityId, hookId: 1)
        
        print("✅ Created HookId: \(hookId)")
        
        // Example 1: Update storage slot
        print("\n💾 Example 1: Updating storage slot")
        
        var storageSlot = LambdaStorageSlot()
        storageSlot = storageSlot.key(Data([0x01, 0x02, 0x03, 0x04])) // 32-byte key
        storageSlot = storageSlot.value(Data([0x05, 0x06, 0x07, 0x08])) // 32-byte value
        
        var storageUpdate = LambdaStorageUpdate()
        storageUpdate = storageUpdate.setStorageSlot(storageSlot)
        
        let sstoreResponse1 = try await LambdaSStoreTransaction()
            .hookId(hookId)
            .addStorageUpdate(storageUpdate)
            .execute(client)
        let sstoreReceipt1 = try await sstoreResponse1.getReceipt(client)
        
        print("✅ Updated storage slot: \(sstoreReceipt1.status)")
        
        // Example 2: Update mapping entries
        print("\n🗺️ Example 2: Updating mapping entries")
        
        var mappingEntry1 = LambdaMappingEntry()
        mappingEntry1 = mappingEntry1.key(Data([0x09, 0x0A, 0x0B, 0x0C])) // 32-byte key
        mappingEntry1 = mappingEntry1.value(Data([0x0D, 0x0E, 0x0F, 0x10])) // 32-byte value
        
        var mappingEntry2 = LambdaMappingEntry()
        mappingEntry2 = mappingEntry2.preimage(Data([0x11, 0x12, 0x13, 0x14])) // Preimage
        mappingEntry2 = mappingEntry2.value(Data([0x15, 0x16, 0x17, 0x18])) // 32-byte value
        
        var mappingEntries = LambdaMappingEntries()
        mappingEntries = mappingEntries.mappingSlot(Data([0x19, 0x1A, 0x1B, 0x1C])) // Mapping slot
        mappingEntries = mappingEntries.setEntries([mappingEntry1, mappingEntry2])
        
        var mappingUpdate = LambdaStorageUpdate()
        mappingUpdate = mappingUpdate.setMappingEntries(mappingEntries)
        
        let sstoreResponse2 = try await LambdaSStoreTransaction()
            .hookId(hookId)
            .addStorageUpdate(mappingUpdate)
            .execute(client)
        let sstoreReceipt2 = try await sstoreResponse2.getReceipt(client)
        
        print("✅ Updated mapping entries: \(sstoreReceipt2.status)")
        
        // Example 3: Multiple storage updates
        print("\n📦 Example 3: Multiple storage updates")
        
        var storageSlot2 = LambdaStorageSlot()
        storageSlot2 = storageSlot2.key(Data([0x1D, 0x1E, 0x1F, 0x20]))
        storageSlot2 = storageSlot2.value(Data([0x21, 0x22, 0x23, 0x24]))
        
        var storageUpdate2 = LambdaStorageUpdate()
        storageUpdate2 = storageUpdate2.setStorageSlot(storageSlot2)
        
        let sstoreResponse3 = try await LambdaSStoreTransaction()
            .hookId(hookId)
            .storageUpdates([storageUpdate, storageUpdate2]) // Multiple updates
            .execute(client)
        let sstoreReceipt3 = try await sstoreResponse3.getReceipt(client)
        
        print("✅ Applied multiple storage updates: \(sstoreReceipt3.status)")
        
        // Example 4: Clear storage updates
        print("\n🧹 Example 4: Clearing storage updates")
        
        let sstoreResponse4 = try await LambdaSStoreTransaction()
            .hookId(hookId)
            .clearStorageUpdates() // Clear all updates
            .execute(client)
        let sstoreReceipt4 = try await sstoreResponse4.getReceipt(client)
        
        print("✅ Cleared storage updates: \(sstoreReceipt4.status)")
        
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
        print("\n🎉 Lambda SSTORE Example completed successfully!")
    }
}
