// SPDX-License-Identifier: Apache-2.0

import Foundation
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

        print("Lambda SSTORE Example")
        print("====================")

        // Create a contract that will serve as our hook
        print("Creating hook contract...")

        let contractKey = PrivateKey.generateEd25519()
        let contractResponse = try await ContractCreateTransaction()
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
            .adminKey(.single(contractKey.publicKey))
            .gas(100000)
            .execute(client)
        let contractReceipt = try await contractResponse.getReceipt(client)
        let contractId = contractReceipt.contractId!

        print("Created hook contract: \(contractId)")

        // Create account with hooks
        print("Creating account with hooks...")

        var evmHookSpec = EvmHookSpec()
        evmHookSpec = evmHookSpec.contractId(contractId)

        let lambdaEvmHook = LambdaEvmHook(spec: evmHookSpec)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook, lambdaEvmHook: lambdaEvmHook,
            adminKey: Key.single(contractKey.publicKey))

        let accountKey = PrivateKey.generateEd25519()
        let accountResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))
            .initialBalance(10)
            .addHook(hookCreationDetails)
            .execute(client)
        let accountReceipt = try await accountResponse.getReceipt(client)
        let accountId = accountReceipt.accountId!

        print("Created account with hooks: \(accountId)")

        // Create HookId for the Lambda SSTORE transaction
        print("Creating HookId...")

        let hookEntityId = HookEntityId(accountId)
        let hookId = HookId(entityId: hookEntityId, hookId: 1)

        print("Created HookId: \(hookId)")

        // Example 1: Update storage slot
        print("Example 1: Updating storage slot")

        var storageSlot = LambdaStorageSlot()
        storageSlot = storageSlot.key(Data([0x01, 0x02, 0x03, 0x04]))  // 32-byte key
        storageSlot = storageSlot.value(Data([0x05, 0x06, 0x07, 0x08]))  // 32-byte value

        var storageUpdate = LambdaStorageUpdate()
        storageUpdate = storageUpdate.setStorageSlot(storageSlot)

        let sstoreResponse1 = try await LambdaSStoreTransaction()
            .hookId(hookId)
            .addStorageUpdate(storageUpdate)
            .execute(client)
        let sstoreReceipt1 = try await sstoreResponse1.getReceipt(client)

        print("Updated storage slot: \(sstoreReceipt1.status)")

        // Example 2: Update mapping entries
        print("Example 2: Updating mapping entries")

        var mappingEntry1 = LambdaMappingEntry()
        mappingEntry1 = mappingEntry1.key(Data([0x09, 0x0A, 0x0B, 0x0C]))  // 32-byte key
        mappingEntry1 = mappingEntry1.value(Data([0x0D, 0x0E, 0x0F, 0x10]))  // 32-byte value

        var mappingEntry2 = LambdaMappingEntry()
        mappingEntry2 = mappingEntry2.preimage(Data([0x11, 0x12, 0x13, 0x14]))  // Preimage
        mappingEntry2 = mappingEntry2.value(Data([0x15, 0x16, 0x17, 0x18]))  // 32-byte value

        var mappingEntries = LambdaMappingEntries()
        mappingEntries = mappingEntries.mappingSlot(Data([0x19, 0x1A, 0x1B, 0x1C]))  // Mapping slot
        mappingEntries = mappingEntries.setEntries([mappingEntry1, mappingEntry2])

        var mappingUpdate = LambdaStorageUpdate()
        mappingUpdate = mappingUpdate.setMappingEntries(mappingEntries)

        let sstoreResponse2 = try await LambdaSStoreTransaction()
            .hookId(hookId)
            .addStorageUpdate(mappingUpdate)
            .execute(client)
        let sstoreReceipt2 = try await sstoreResponse2.getReceipt(client)

        print("Updated mapping entries: \(sstoreReceipt2.status)")

        // Example 3: Multiple storage updates
        print("Example 3: Multiple storage updates")

        var storageSlot2 = LambdaStorageSlot()
        storageSlot2 = storageSlot2.key(Data([0x1D, 0x1E, 0x1F, 0x20]))
        storageSlot2 = storageSlot2.value(Data([0x21, 0x22, 0x23, 0x24]))

        var storageUpdate2 = LambdaStorageUpdate()
        storageUpdate2 = storageUpdate2.setStorageSlot(storageSlot2)

        let sstoreResponse3 = try await LambdaSStoreTransaction()
            .hookId(hookId)
            .storageUpdates([storageUpdate, storageUpdate2])  // Multiple updates
            .execute(client)
        let sstoreReceipt3 = try await sstoreResponse3.getReceipt(client)

        print("Applied multiple storage updates: \(sstoreReceipt3.status)")

        // Example 4: Clear storage updates
        print("Example 4: Clearing storage updates")

        let sstoreResponse4 = try await LambdaSStoreTransaction()
            .hookId(hookId)
            .clearStorageUpdates()  // Clear all updates
            .execute(client)
        let sstoreReceipt4 = try await sstoreResponse4.getReceipt(client)

        print("Cleared storage updates: \(sstoreReceipt4.status)")

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
        print("\nLambda SSTORE Example completed successfully!")
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
