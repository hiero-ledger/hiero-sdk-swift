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

        print("Transfer Transaction Hooks Example")
        print("===================================")

        let (hookContractId, hookContractKey) = try await createHookContract(client)

        let hookDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            evmHook: EvmHook(contractId: hookContractId)
        )

        let (senderAccountId, senderKey) = try await createAccountWithHook(
            client, hookDetails: hookDetails, label: "sender")
        let (receiverAccountId, receiverKey) = try await createAccountWithHook(
            client, hookDetails: hookDetails, label: "receiver", maxAutoAssociations: 100)

        try await performHbarTransfer(
            client, senderAccountId: senderAccountId, senderKey: senderKey, receiverAccountId: receiverAccountId)
        try await performFungibleTokenTransfer(
            client, senderAccountId: senderAccountId, senderKey: senderKey, receiverAccountId: receiverAccountId)

        try await cleanup(
            client,
            sender: (senderAccountId, senderKey),
            receiver: (receiverAccountId, receiverKey),
            hookContract: (hookContractId, hookContractKey),
            operatorAccountId: env.operatorAccountId
        )

        print("\nTransfer With Hooks Example completed successfully!")
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

    private static func createAccountWithHook(
        _ client: Client, hookDetails: HookCreationDetails, label: String, maxAutoAssociations: Int32? = nil
    ) async throws -> (AccountId, PrivateKey) {
        print("Creating \(label) account with hook...")

        let key = PrivateKey.generateEd25519()
        var tx = AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(10)
            .addHook(hookDetails)

        if let maxAutoAssociations {
            tx = tx.maxAutomaticTokenAssociations(maxAutoAssociations)
        }

        let accountId = try await tx.execute(client).getReceipt(client).accountId!
        print("Created \(label) account: \(accountId)")
        return (accountId, key)
    }

    private static func performHbarTransfer(
        _ client: Client, senderAccountId: AccountId, senderKey: PrivateKey, receiverAccountId: AccountId
    ) async throws {
        print("\nExample 1: HBAR transfer with pre-tx allowance hook")

        let hbarHook = FungibleHookCall(
            hookCall: HookCall(hookId: 1, evmHookCall: EvmHookCall(data: Data([0x01, 0x02]), gasLimit: 20000)),
            hookType: .preHookSender
        )

        let receipt = try await TransferTransaction()
            .addHbarTransferWithHook(senderAccountId, Hbar(-1), hbarHook)
            .hbarTransfer(receiverAccountId, Hbar(1))
            .freezeWith(client)
            .sign(senderKey)
            .execute(client)
            .getReceipt(client)

        print("HBAR transfer completed with status: \(receipt.status)")
    }

    private static func performFungibleTokenTransfer(
        _ client: Client, senderAccountId: AccountId, senderKey: PrivateKey, receiverAccountId: AccountId
    ) async throws {
        print("\nExample 2: Fungible token transfer with pre-post allowance hook")

        let fungibleTokenId = try await TokenCreateTransaction()
            .name("Example Fungible Token")
            .symbol("EFT")
            .tokenType(.fungibleCommon)
            .decimals(2)
            .initialSupply(10000)
            .treasuryAccountId(senderAccountId)
            .adminKey(.single(senderKey.publicKey))
            .supplyKey(.single(senderKey.publicKey))
            .freezeWith(client)
            .sign(senderKey)
            .execute(client)
            .getReceipt(client)
            .tokenId!

        print("Created fungible token: \(fungibleTokenId)")

        let fungibleTokenHook = FungibleHookCall(
            hookCall: HookCall(hookId: 1, evmHookCall: EvmHookCall(data: Data([0x07, 0x08]), gasLimit: 20000)),
            hookType: .prePostHookSender
        )

        let receipt = try await TransferTransaction()
            .addTokenTransferWithHook(fungibleTokenId, senderAccountId, -1000, fungibleTokenHook)
            .tokenTransfer(fungibleTokenId, receiverAccountId, 1000)
            .freezeWith(client)
            .sign(senderKey)
            .execute(client)
            .getReceipt(client)

        print("Fungible token transfer completed with status: \(receipt.status)")
    }

    private static func cleanup(
        _ client: Client,
        sender: (AccountId, PrivateKey),
        receiver: (AccountId, PrivateKey),
        hookContract: (ContractId, PrivateKey),
        operatorAccountId: AccountId
    ) async throws {
        print("\nCleaning up...")

        _ = try await AccountDeleteTransaction()
            .accountId(sender.0)
            .transferAccountId(operatorAccountId)
            .freezeWith(client)
            .sign(sender.1)
            .execute(client)
            .getReceipt(client)

        _ = try await AccountDeleteTransaction()
            .accountId(receiver.0)
            .transferAccountId(operatorAccountId)
            .freezeWith(client)
            .sign(receiver.1)
            .execute(client)
            .getReceipt(client)

        _ = try await ContractDeleteTransaction()
            .contractId(hookContract.0)
            .transferAccountId(operatorAccountId)
            .freezeWith(client)
            .sign(hookContract.1)
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
