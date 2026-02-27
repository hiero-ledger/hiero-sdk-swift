// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()

        let client = try Client.forName(env.networkName)
        client.setOperator(env.operatorAccountId, env.operatorKey)

        print("Hook Store Example")
        print("==================")

        print("Creating hook contract...")

        let contractKey = PrivateKey.generateEd25519()
        let hookBytecodeHex =
            "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
        let hookBytecode = dataFromHex(hookBytecodeHex)
        let contractResponse = try await ContractCreateTransaction()
            .bytecode(hookBytecode)
            .adminKey(.single(contractKey.publicKey))
            .gas(100000)
            .execute(client)
        let contractReceipt = try await contractResponse.getReceipt(client)
        let contractId = contractReceipt.contractId!

        print("Created hook contract: \(contractId)")

        print("Creating account with hooks...")

        let evmHook = EvmHook(contractId: contractId)

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook, evmHook: evmHook,
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

        print("Creating HookId...")

        let hookEntityId = HookEntityId(accountId: accountId)
        let hookId = HookId(entityId: hookEntityId, hookId: 1)

        print("Created HookId: \(hookId)")

        // Example 1: Update storage slot
        print("Example 1: Updating storage slot")

        var storageSlot = EvmHookStorageSlot()
        storageSlot = storageSlot.key(Data([0x01, 0x02, 0x03, 0x04]))
        storageSlot = storageSlot.value(Data([0x05, 0x06, 0x07, 0x08]))

        var storageUpdate = EvmHookStorageUpdate()
        storageUpdate = storageUpdate.setStorageSlot(storageSlot)

        let storeResponse1 = try await HookStoreTransaction()
            .hookId(hookId)
            .addStorageUpdate(storageUpdate)
            .execute(client)
        let storeReceipt1 = try await storeResponse1.getReceipt(client)

        print("Updated storage slot: \(storeReceipt1.status)")

        // Example 2: Update mapping entries
        print("Example 2: Updating mapping entries")

        var mappingEntry1 = EvmHookMappingEntry()
        mappingEntry1 = mappingEntry1.key(Data([0x09, 0x0A, 0x0B, 0x0C]))
        mappingEntry1 = mappingEntry1.value(Data([0x0D, 0x0E, 0x0F, 0x10]))

        var mappingEntry2 = EvmHookMappingEntry()
        mappingEntry2 = mappingEntry2.preimage(Data([0x11, 0x12, 0x13, 0x14]))
        mappingEntry2 = mappingEntry2.value(Data([0x15, 0x16, 0x17, 0x18]))

        var mappingEntries = EvmHookMappingEntries()
        mappingEntries = mappingEntries.mappingSlot(Data([0x19, 0x1A, 0x1B, 0x1C]))
        mappingEntries = mappingEntries.setEntries([mappingEntry1, mappingEntry2])

        var mappingUpdate = EvmHookStorageUpdate()
        mappingUpdate = mappingUpdate.setMappingEntries(mappingEntries)

        let storeResponse2 = try await HookStoreTransaction()
            .hookId(hookId)
            .addStorageUpdate(mappingUpdate)
            .execute(client)
        let storeReceipt2 = try await storeResponse2.getReceipt(client)

        print("Updated mapping entries: \(storeReceipt2.status)")

        // Example 3: Multiple storage updates
        print("Example 3: Multiple storage updates")

        var storageSlot2 = EvmHookStorageSlot()
        storageSlot2 = storageSlot2.key(Data([0x1D, 0x1E, 0x1F, 0x20]))
        storageSlot2 = storageSlot2.value(Data([0x21, 0x22, 0x23, 0x24]))

        var storageUpdate2 = EvmHookStorageUpdate()
        storageUpdate2 = storageUpdate2.setStorageSlot(storageSlot2)

        let storeResponse3 = try await HookStoreTransaction()
            .hookId(hookId)
            .storageUpdates([storageUpdate, storageUpdate2])
            .execute(client)
        let storeReceipt3 = try await storeResponse3.getReceipt(client)

        print("Applied multiple storage updates: \(storeReceipt3.status)")

        // Example 4: Clear storage updates
        print("Example 4: Clearing storage updates")

        let storeResponse4 = try await HookStoreTransaction()
            .hookId(hookId)
            .clearStorageUpdates()
            .execute(client)
        let storeReceipt4 = try await storeResponse4.getReceipt(client)

        print("Cleared storage updates: \(storeReceipt4.status)")

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
        print("\nHook Store Example completed successfully!")
    }
}

private func dataFromHex(_ hex: String) -> Data {
    var data = Data(capacity: hex.count / 2)
    var index = hex.startIndex
    while index < hex.endIndex {
        let nextIndex = hex.index(index, offsetBy: 2)
        if let byte = UInt8(hex[index..<nextIndex], radix: 16) {
            data.append(byte)
        }
        index = nextIndex
    }
    return data
}

extension Environment {
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    internal var operatorKey: PrivateKey {
        PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
    }

    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
