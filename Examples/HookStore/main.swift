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

        let (contractId, contractKey) = try await createHookContract(client)
        let (accountId, hookId) = try await createAccountWithHook(
            client, contractId: contractId, contractKey: contractKey)

        try await updateStorageSlot(client, hookId: hookId)
        let (storageUpdate, storageUpdate2) = try await updateMappingEntries(client, hookId: hookId)
        try await applyMultipleStorageUpdates(client, hookId: hookId, updates: [storageUpdate, storageUpdate2])
        try await clearStorageUpdates(client, hookId: hookId)

        try await cleanup(
            client, accountId: accountId, contractId: contractId, operatorAccountId: env.operatorAccountId)

        print("\nHook Store Example completed successfully!")
    }

    private static func createHookContract(_ client: Client) async throws -> (ContractId, PrivateKey) {
        print("Creating hook contract...")

        let contractKey = PrivateKey.generateEd25519()
        let contractId = try await ContractCreateTransaction()
            .bytecode(dataFromHex(hookBytecodeHex))
            .adminKey(.single(contractKey.publicKey))
            .gas(100000)
            .execute(client)
            .getReceipt(client)
            .contractId!

        print("Created hook contract: \(contractId)")
        return (contractId, contractKey)
    }

    private static func createAccountWithHook(
        _ client: Client, contractId: ContractId, contractKey: PrivateKey
    ) async throws -> (AccountId, HookId) {
        print("Creating account with hooks...")

        let evmHook = EvmHook(contractId: contractId)
        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook, evmHook: evmHook,
            adminKey: Key.single(contractKey.publicKey))

        let accountKey = PrivateKey.generateEd25519()
        let accountId = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(accountKey.publicKey))
            .initialBalance(10)
            .addHook(hookCreationDetails)
            .execute(client)
            .getReceipt(client)
            .accountId!

        print("Created account with hooks: \(accountId)")

        let hookEntityId = HookEntityId(accountId: accountId)
        let hookId = HookId(entityId: hookEntityId, hookId: 1)
        print("Created HookId: \(hookId)")

        return (accountId, hookId)
    }

    private static func updateStorageSlot(_ client: Client, hookId: HookId) async throws {
        print("Example 1: Updating storage slot")

        var storageSlot = EvmHookStorageSlot()
        storageSlot = storageSlot.key(Data([0x01, 0x02, 0x03, 0x04]))
        storageSlot = storageSlot.value(Data([0x05, 0x06, 0x07, 0x08]))

        var storageUpdate = EvmHookStorageUpdate()
        storageUpdate = storageUpdate.setStorageSlot(storageSlot)

        let receipt = try await HookStoreTransaction()
            .hookId(hookId)
            .addStorageUpdate(storageUpdate)
            .execute(client)
            .getReceipt(client)

        print("Updated storage slot: \(receipt.status)")
    }

    private static func updateMappingEntries(
        _ client: Client, hookId: HookId
    ) async throws -> (EvmHookStorageUpdate, EvmHookStorageUpdate) {
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

        let receipt = try await HookStoreTransaction()
            .hookId(hookId)
            .addStorageUpdate(mappingUpdate)
            .execute(client)
            .getReceipt(client)

        print("Updated mapping entries: \(receipt.status)")

        var storageSlot = EvmHookStorageSlot()
        storageSlot = storageSlot.key(Data([0x1D, 0x1E, 0x1F, 0x20]))
        storageSlot = storageSlot.value(Data([0x21, 0x22, 0x23, 0x24]))

        var storageUpdate = EvmHookStorageUpdate()
        storageUpdate = storageUpdate.setStorageSlot(storageSlot)

        return (mappingUpdate, storageUpdate)
    }

    private static func applyMultipleStorageUpdates(
        _ client: Client, hookId: HookId, updates: [EvmHookStorageUpdate]
    ) async throws {
        print("Example 3: Multiple storage updates")

        let receipt = try await HookStoreTransaction()
            .hookId(hookId)
            .storageUpdates(updates)
            .execute(client)
            .getReceipt(client)

        print("Applied multiple storage updates: \(receipt.status)")
    }

    private static func clearStorageUpdates(_ client: Client, hookId: HookId) async throws {
        print("Example 4: Clearing storage updates")

        let receipt = try await HookStoreTransaction()
            .hookId(hookId)
            .clearStorageUpdates()
            .execute(client)
            .getReceipt(client)

        print("Cleared storage updates: \(receipt.status)")
    }

    private static func cleanup(
        _ client: Client, accountId: AccountId, contractId: ContractId, operatorAccountId: AccountId
    ) async throws {
        print("Cleaning up...")

        _ = try await AccountDeleteTransaction()
            .accountId(accountId)
            .transferAccountId(operatorAccountId)
            .execute(client)
            .getReceipt(client)

        _ = try await ContractDeleteTransaction()
            .contractId(contractId)
            .transferAccountId(operatorAccountId)
            .execute(client)
            .getReceipt(client)

        print("Cleanup completed")
    }
}

// swiftlint:disable:next line_length
private let hookBytecodeHex =
    "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"

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
