// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

internal final class TransferTransactionHooks: XCTestCase {

    internal func test_HbarTransferWithPreTxHook() async throws {

        // Given
        let lambdaId = try await ContractCreateTransaction()
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
            .gas(300000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 2,
            lambdaEvmHook: lambdaEvmHook
        )

        let key = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(1)
            .addHook(hookCreationDetails)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        let hookCall = FungibleHookCall(
            hookCall: HookCall(hookId: 2, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .preTxAllowanceHook
        )

        // When
        let transferTx = TransferTransaction()
            .hbarTransferWithHook(accountId, Hbar(1), hookCall)
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))

        // Then
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }

    internal func testHbarTransferWithPrePostTxHook() async throws {

        // Given
        let lambdaId = try await ContractCreateTransaction()
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
            .gas(300000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 2,
            lambdaEvmHook: lambdaEvmHook
        )

        let key = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(1)
            .addHook(hookCreationDetails)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        let hookCall = FungibleHookCall(
            hookCall: HookCall(hookId: 2, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .prePostTxAllowanceHook
        )

        // When
        let transferTx = TransferTransaction()
            .hbarTransferWithHook(accountId, Hbar(1), hookCall)
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))

        // Then
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }

    internal func test_TokenTransferWithPreTxHook() async throws {

        // Given
        let lambdaId = try await ContractCreateTransaction()
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
            .gas(300000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 2,
            lambdaEvmHook: lambdaEvmHook
        )

        let key = PrivateKey.generateEd25519()
        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
            .initialBalance(1)
            .addHook(hookCreationDetails)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let accountId = try XCTUnwrap(receipt.accountId)

        let tokenId = try await TokenCreateTransaction()
            .name("Test Token")
            .symbol("TT")
            .decimals(2)
            .initialSupply(1000)
            .treasuryAccountId(testEnv.operator.accountId)
            .adminKey(.single(testEnv.operator.privateKey.publicKey))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .tokenId!

        _ = try await TokenAssociateTransaction(accountId: accountId, tokenIds: [tokenId])
            .freezeWith(testEnv.client)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let hookCall = FungibleHookCall(
            hookCall: HookCall(hookId: 2, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .preTxAllowanceHook
        )

        // When
        let transferTx = TransferTransaction()
            .tokenTransferWithHook(tokenId, accountId, 1000, hookCall)
            .tokenTransfer(tokenId, testEnv.operator.accountId, -1000)

        // Then
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }

    internal func disabledTestNftTransferWithSenderAndReceiverHooks() async throws {

        // Given
        let lambdaId = try await ContractCreateTransaction()
            .bytecode(
                Data(
                    hexEncoded:
                        "608060405234801561001057600080fd5b50610167806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80632f570a2314610030575b600080fd5b61004a600480360381019061004591906100b6565b610060565b604051610057919061010a565b60405180910390f35b60006001905092915050565b60008083601f84011261007e57600080fd5b8235905067ffffffffffffffff81111561009757600080fd5b6020830191508360018202830111156100af57600080fd5b9250929050565b600080602083850312156100c957600080fd5b600083013567ffffffffffffffff8111156100e357600080fd5b6100ef8582860161006c565b92509250509250929050565b61010481610125565b82525050565b600060208201905061011f60008301846100fb565b92915050565b6000811515905091905056fea264697066735822122097fc0c3ac3155b53596be3af3b4d2c05eb5e273c020ee447f01b72abc3416e1264736f6c63430008000033"
                )!
            )
            .gas(300000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .contractId!

        var lambdaEvmHook = LambdaEvmHook()
        lambdaEvmHook.spec.contractId = lambdaId

        let hookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 1,
            lambdaEvmHook: lambdaEvmHook
        )

        let senderKey = PrivateKey.generateEd25519()
        let senderReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(senderKey.publicKey))
            .initialBalance(2)
            .addHook(hookCreationDetails)
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let senderAccountId = try XCTUnwrap(senderReceipt.accountId)

        var receiverLambdaEvmHook = LambdaEvmHook()
        receiverLambdaEvmHook.spec.contractId = lambdaId

        let receiverHookCreationDetails = HookCreationDetails(
            hookExtensionPoint: .accountAllowanceHook,
            hookId: 2,
            lambdaEvmHook: receiverLambdaEvmHook
        )

        let receiverKey = PrivateKey.generateEd25519()
        let receiverReceipt = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(receiverKey.publicKey))
            .initialBalance(2)
            .addHook(receiverHookCreationDetails)
            .freezeWith(testEnv.client)
            .sign(receiverKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
        let receiverAccountId = try XCTUnwrap(receiverReceipt.accountId)

        let tokenId = try await TokenCreateTransaction()
            .name("Test NFT")
            .symbol("TNFT")
            .tokenType(.nonFungibleUnique)
            .initialSupply(0)
            .treasuryAccountId(senderAccountId)
            .adminKey(.single(senderKey.publicKey))
            .supplyKey(.single(senderKey.publicKey))
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
            .tokenId!

        let _ = try await TokenMintTransaction(tokenId: tokenId)
            .metadata([Data("NFT Metadata".utf8)])
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenAssociateTransaction(accountId: receiverAccountId, tokenIds: [tokenId])
            .freezeWith(testEnv.client)
            .sign(receiverKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let senderCall = NftHookCall(
            hookCall: HookCall(hookId: 1, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .preHook
        )

        let receiverCall = NftHookCall(
            hookCall: HookCall(hookId: 2, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .preHook
        )

        let nftId = NftId(tokenId: tokenId, serial: 1)

        // When
        let transferTx = TransferTransaction()
            .nftTransferWithHooks(nftId, senderAccountId, receiverAccountId, senderCall, receiverCall)

        // Then
        let response = try await transferTx.execute(testEnv.client)
        let transferReceipt = try await response.getReceipt(testEnv.client)

        XCTAssertEqual(transferReceipt.status, .success)
    }
}
