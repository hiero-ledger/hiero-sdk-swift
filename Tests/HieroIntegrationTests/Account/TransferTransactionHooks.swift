// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroTestSupport
import XCTest

internal final class TransferTransactionHooks: HieroIntegrationTestCase {

    internal func test_HbarTransferWithPreTxHook() async throws {
        let hookContractId = try await createEvmHookContract()
        let hookDetails = createHookDetails(contractId: hookContractId, hookId: 2)
        let (accountId, _) = try await createAccountWithHook(
            hookDetails: hookDetails,
            initialBalance: Hbar(1)
        )

        let hookCall = FungibleHookCall(
            hookCall: HookCall(hookId: 2, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .preHookReceiver
        )

        let txReceipt = try await TransferTransaction()
            .addHbarTransferWithHook(accountId, Hbar(1), hookCall)
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .maxTransactionFee(Hbar(20))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(txReceipt.status, .success)
    }

    internal func test_HbarTransferWithPrePostTxHook() async throws {
        let hookContractId = try await createEvmHookContract()
        let hookDetails = createHookDetails(contractId: hookContractId, hookId: 2)
        let (accountId, _) = try await createAccountWithHook(
            hookDetails: hookDetails,
            initialBalance: Hbar(1)
        )

        let hookCall = FungibleHookCall(
            hookCall: HookCall(hookId: 2, evmHookCall: EvmHookCall(gasLimit: 25000)),
            hookType: .prePostHookReceiver
        )

        let txReceipt = try await TransferTransaction()
            .addHbarTransferWithHook(accountId, Hbar(1), hookCall)
            .hbarTransfer(testEnv.operator.accountId, Hbar(-1))
            .maxTransactionFee(Hbar(20))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(txReceipt.status, .success)
    }

    internal func test_TokenTransferWithPreTxHook() async throws {
        let hookContractId = try await createEvmHookContract()
        let hookDetails = createHookDetails(contractId: hookContractId, hookId: 2)
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
            hookType: .preHookReceiver
        )

        let txReceipt = try await TransferTransaction()
            .addTokenTransferWithHook(tokenId, accountId, 1000, hookCall)
            .tokenTransfer(tokenId, testEnv.operator.accountId, -1000)
            .maxTransactionFee(Hbar(20))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(txReceipt.status, .success)
    }

    internal func test_NftTransferWithSenderAndReceiverHooks() async throws {
        let hookContractId = try await createEvmHookContract()

        let senderHookDetails = createHookDetails(contractId: hookContractId, hookId: 1)
        let (senderAccountId, senderKey) = try await createAccountWithHook(
            hookDetails: senderHookDetails,
            initialBalance: Hbar(2)
        )

        let receiverHookDetails = createHookDetails(contractId: hookContractId, hookId: 2)
        let (receiverAccountId, receiverKey) = try await createAccountWithHook(
            hookDetails: receiverHookDetails,
            initialBalance: Hbar(2)
        )

        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name("Test NFT")
                .symbol("TNFT")
                .tokenType(.nonFungibleUnique)
                .initialSupply(0)
                .treasuryAccountId(senderAccountId)
                .supplyKey(.single(supplyKey.publicKey))
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

        let txReceipt = try await TransferTransaction()
            .addNftTransferWithHook(nftId, senderAccountId, receiverAccountId, senderCall, receiverCall)
            .maxTransactionFee(Hbar(20))
            .freezeWith(testEnv.client)
            .sign(senderKey)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        XCTAssertEqual(txReceipt.status, .success)
    }
}
