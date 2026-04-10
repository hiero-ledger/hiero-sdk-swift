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

        print("Contract Hooks Example")
        print("=====================")

        let (hookContractId, hookContractKey) = try await createHookContract(client)

        let evmHook = EvmHook(contractId: hookContractId)

        let contractId = try await createContractWithHooks(client, evmHook: evmHook, hookContractKey: hookContractKey)
        try await addHooksToContract(client, contractId: contractId, evmHook: evmHook, hookContractKey: hookContractKey)
        try await deleteHooksFromContract(client, contractId: contractId)
        try await cleanup(
            client, contractId: contractId, hookContractId: hookContractId, operatorAccountId: env.operatorAccountId)

        print("\nContract Hooks Example completed successfully!")
    }

    private static func createHookContract(_ client: Client) async throws -> (ContractId, PrivateKey) {
        print("Creating hook contract...")

        let hookContractKey = PrivateKey.generateEd25519()
        let hookContractResponse = try await ContractCreateTransaction()
            .bytecode(dataFromHex(hookBytecode))
            .adminKey(.single(hookContractKey.publicKey))
            .gas(100000)
            .execute(client)
        let hookContractId = try await hookContractResponse.getReceipt(client).contractId!

        print("Created hook contract: \(hookContractId)")
        return (hookContractId, hookContractKey)
    }

    private static func createContractWithHooks(
        _ client: Client, evmHook: EvmHook, hookContractKey: PrivateKey
    ) async throws -> ContractId {
        print("Example 1: Creating contract with hooks")

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook, hookId: 1, evmHook: evmHook,
            adminKey: Key.single(hookContractKey.publicKey))

        let contractKey = PrivateKey.generateEd25519()
        let contractResponse = try await ContractCreateTransaction()
            .bytecode(dataFromHex(hookBytecode))
            .adminKey(.single(contractKey.publicKey))
            .gas(200000)
            .addHook(hookCreationDetails)
            .execute(client)
        let contractId = try await contractResponse.getReceipt(client).contractId!

        print("Created contract with hooks: \(contractId)")
        return contractId
    }

    private static func addHooksToContract(
        _ client: Client, contractId: ContractId, evmHook: EvmHook, hookContractKey: PrivateKey
    ) async throws {
        print("Example 2: Updating contract to add more hooks")

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook, hookId: 2, evmHook: evmHook,
            adminKey: Key.single(hookContractKey.publicKey))

        let updateReceipt = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToCreate(hookCreationDetails)
            .execute(client)
            .getReceipt(client)

        print("Updated contract with additional hooks: \(updateReceipt.status)")
    }

    private static func deleteHooksFromContract(_ client: Client, contractId: ContractId) async throws {
        print("Example 3: Updating contract to delete hooks")

        let deleteReceipt = try await ContractUpdateTransaction()
            .contractId(contractId)
            .addHookToDelete(1)
            .execute(client)
            .getReceipt(client)

        print("Updated contract to delete hooks: \(deleteReceipt.status)")
    }

    private static func cleanup(
        _ client: Client, contractId: ContractId, hookContractId: ContractId, operatorAccountId: AccountId
    ) async throws {
        print("Cleaning up...")

        _ = try await ContractDeleteTransaction()
            .contractId(contractId)
            .transferAccountId(operatorAccountId)
            .execute(client)
            .getReceipt(client)

        _ = try await ContractDeleteTransaction()
            .contractId(hookContractId)
            .transferAccountId(operatorAccountId)
            .execute(client)
            .getReceipt(client)

        print("Cleanup completed")
    }
}

// swiftlint:disable:next line_length
private let hookBytecode =
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
