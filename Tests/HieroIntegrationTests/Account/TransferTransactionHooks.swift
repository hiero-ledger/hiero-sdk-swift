// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TransferTransactionHooks: HieroIntegrationTestCase {

    internal func test_HbarTransferWithPreTxHook() async throws {
        // Given
        let lambdaId = try await createEvmHookContract()
        let hookDetails = createHookDetails(contractId: lambdaId, hookId: 2)
        let (accountId, _) = try await createAccountWithHook(
            hookDetails: hookDetails,
            initialBalance: Hbar(1)
        )

        let hookCall = FungibleHookCall(
            hookCall: HookCall(hookId: 2, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .preTxAllowanceHook
        )

        // When
        let txReceipt = TransferTransaction()
            .hbarTransferWithHook(accountId, Hbar(1), hookCall)
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(txReceipt.status, .success)
    }

    internal func test_HbarTransferWithPrePostTxHook() async throws {
        // Given
        let lambdaId = try await createEvmHookContract()
        let hookDetails = createHookDetails(contractId: lambdaId, hookId: 2)
        let (accountId, _) = try await createAccountWithHook(
            hookDetails: hookDetails,
            initialBalance: Hbar(1)
        )

        let hookCall = FungibleHookCall(
            hookCall: HookCall(hookId: 2, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .prePostTxAllowanceHook
        )

        // When
        let txReceipt = TransferTransaction()
            .hbarTransferWithHook(accountId, Hbar(1), hookCall)
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(txReceipt.status, .success)
    }

    internal func test_TokenTransferWithPreTxHook() async throws {
        // Given
        let lambdaId = try await createEvmHookContract()
        let hookDetails = createHookDetails(contractId: lambdaId, hookId: 2)
        let (accountId, accountKey) = try await createAccountWithHook(
            hookDetails: hookDetails,
            initialBalance: Hbar(1)
        )

        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test Token")
                .symbol("TT")
                .decimals(2)
                .initialSupply(1000)
                .treasuryAccountId(testEnv.operator.accountId)
        )

        try await associateToken(tokenId, with: accountId, key: accountKey)

        let hookCall = FungibleHookCall(
            hookCall: HookCall(hookId: 2, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .preTxAllowanceHook
        )

        // When
        let txReceipt = TransferTransaction()
            .tokenTransferWithHook(tokenId, accountId, 1000, hookCall)
            .tokenTransfer(tokenId, testEnv.operator.accountId, -1000)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(txReceipt.status, .success)
    }

    internal func disabled_test_NftTransferWithSenderAndReceiverHooks() async throws {
        // Given
        let lambdaId = try await createEvmHookContract()

        let senderHookDetails = createHookDetails(contractId: lambdaId, hookId: 1)
        let senderKey = PrivateKey.generateEd25519()
        let senderTx = AccountCreateTransaction()
            .keyWithoutAlias(.single(senderKey.publicKey))
            .initialBalance(Hbar(2))
            .addHook(senderHookDetails)
            .freezeWith(testEnv.client)
            .sign(senderKey)
        let senderAccountId = try await createAccount(senderTx, key: senderKey)

        let receiverHookDetails = createHookDetails(contractId: lambdaId, hookId: 2)
        let receiverKey = PrivateKey.generateEd25519()
        let receiverTx = AccountCreateTransaction()
            .keyWithoutAlias(.single(receiverKey.publicKey))
            .initialBalance(Hbar(2))
            .addHook(receiverHookDetails)
            .freezeWith(testEnv.client)
            .sign(receiverKey)
        let receiverAccountId = try await createAccount(receiverTx, key: receiverKey)

        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(.nonFungibleUnique)
                .initialSupply(0)
                .treasuryAccountId(senderAccountId)
                .supplyKey(.single(supplyKey.publicKey))
                .freezeWith(testEnv.client)
                .sign(senderKey),
            supplyKey: supplyKey
        )

        _ = try await TokenMintTransaction(tokenId: tokenId)
            .metadata([Data("NFT Metadata".utf8)])
            .sign(supplyKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        try await associateToken(tokenId, with: receiverAccountId, key: receiverKey)

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
        let txReceipt = TransferTransaction()
            .nftTransferWithHooks(nftId, senderAccountId, receiverAccountId, senderCall, receiverCall)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // Then
        XCTAssertEqual(txReceipt.status, .success)
    }
}
