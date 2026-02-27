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

        // Create a contract that will serve as our hook
        print("Creating hook contract...")

        let hookContractKey = PrivateKey.generateEd25519()
        let hookContractResponse = try await ContractCreateTransaction()
            .bytecode(dataFromHex(
                "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
            ))
            .adminKey(.single(hookContractKey.publicKey))
            .gas(100000)
            .execute(client)
        let hookContractReceipt = try await hookContractResponse.getReceipt(client)
        let hookContractId = hookContractReceipt.contractId!

        print("Created hook contract: \(hookContractId)")

        let evmHook = EvmHook(contractId: hookContractId)

        let hookDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            evmHook: evmHook
        )

        // Create sender account with hook
        print("Creating sender account with hook...")
        let senderKey = PrivateKey.generateEd25519()
        let senderResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(senderKey.publicKey))
            .initialBalance(10)
            .addHook(hookDetails)
            .execute(client)
        let senderReceipt = try await senderResponse.getReceipt(client)
        let senderAccountId = senderReceipt.accountId!

        print("Created sender account: \(senderAccountId)")

        // Create receiver account with hook
        print("Creating receiver account with hook...")
        let receiverKey = PrivateKey.generateEd25519()
        let receiverResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(receiverKey.publicKey))
            .maxAutomaticTokenAssociations(100)
            .initialBalance(10)
            .addHook(hookDetails)
            .execute(client)
        let receiverReceipt = try await receiverResponse.getReceipt(client)
        let receiverAccountId = receiverReceipt.accountId!

        print("Created receiver account: \(receiverAccountId)")

        // Example 1: HBAR transfer with pre-tx allowance hook
        print("\nExample 1: HBAR transfer with pre-tx allowance hook")

        let hbarHook = FungibleHookCall(
            hookCall: HookCall(hookId: 1, evmHookCall: EvmHookCall(data: Data([0x01, 0x02]), gasLimit: 20000)),
            hookType: .preHookSender
        )

        let hbarTransferResponse = try await TransferTransaction()
            .addHbarTransferWithHook(senderAccountId, Hbar(-1), hbarHook)
            .hbarTransfer(receiverAccountId, Hbar(1))
            .freezeWith(client)
            .sign(senderKey)
            .execute(client)
        let hbarTransferReceipt = try await hbarTransferResponse.getReceipt(client)

        print("HBAR transfer completed with status: \(hbarTransferReceipt.status)")

        // Example 2: Fungible token transfer with pre-post allowance hook
        print("\nExample 2: Fungible token transfer with pre-post allowance hook")

        let fungibleTokenResponse = try await TokenCreateTransaction()
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
        let fungibleTokenReceipt = try await fungibleTokenResponse.getReceipt(client)
        let fungibleTokenId = fungibleTokenReceipt.tokenId!

        print("Created fungible token: \(fungibleTokenId)")

        let fungibleTokenHook = FungibleHookCall(
            hookCall: HookCall(hookId: 1, evmHookCall: EvmHookCall(data: Data([0x07, 0x08]), gasLimit: 20000)),
            hookType: .prePostHookSender
        )

        let fungibleTransferResponse = try await TransferTransaction()
            .addTokenTransferWithHook(fungibleTokenId, senderAccountId, -1000, fungibleTokenHook)
            .tokenTransfer(fungibleTokenId, receiverAccountId, 1000)
            .freezeWith(client)
            .sign(senderKey)
            .execute(client)
        let fungibleTransferReceipt = try await fungibleTransferResponse.getReceipt(client)

        print("Fungible token transfer completed with status: \(fungibleTransferReceipt.status)")

        // Cleanup
        print("\nCleaning up...")

        _ = try await AccountDeleteTransaction()
            .accountId(senderAccountId)
            .transferAccountId(env.operatorAccountId)
            .freezeWith(client)
            .sign(senderKey)
            .execute(client)
            .getReceipt(client)

        _ = try await AccountDeleteTransaction()
            .accountId(receiverAccountId)
            .transferAccountId(env.operatorAccountId)
            .freezeWith(client)
            .sign(receiverKey)
            .execute(client)
            .getReceipt(client)

        _ = try await ContractDeleteTransaction()
            .contractId(hookContractId)
            .transferAccountId(env.operatorAccountId)
            .freezeWith(client)
            .sign(hookContractKey)
            .execute(client)
            .getReceipt(client)

        print("Cleanup completed")
        print("\nTransfer With Hooks Example completed successfully!")
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
