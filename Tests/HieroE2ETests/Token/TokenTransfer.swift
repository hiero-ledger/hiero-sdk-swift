// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class TokenTransfer: XCTestCase {
    internal func testBasic() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let aliceFut = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)

        let (alice, bob) = try await (aliceFut, bobFut)

        let token = try await FungibleToken.create(testEnv, owner: alice, initialSupply: 10)

        addTeardownBlock {
            try await token.burn(testEnv, supply: 10)
            try await token.delete(testEnv)
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenGrantKycTransaction(accountId: bob.id, tokenId: token.id)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .tokenTransfer(token.id, alice.id, -10)
            .tokenTransfer(token.id, bob.id, 10)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .tokenTransfer(token.id, bob.id, -10)
            .tokenTransfer(token.id, alice.id, 10)
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testInsufficientBalanceForFeeFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let aliceFut = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)
        async let cherryFut = makeAccount(testEnv)

        let (alice, bob, cherry) = try await (aliceFut, bobFut, cherryFut)

        let fee = FixedFee(
            amount: 5_000_000_000,
            denominatingTokenId: 0,
            feeCollectorAccountId: alice.id,
            allCollectorsAreExempt: true
        )

        let receipt = try await TokenCreateTransaction(
            name: "ffff",
            symbol: "F",
            initialSupply: 1,
            treasuryAccountId: alice.id,
            adminKey: .single(alice.key.publicKey),
            wipeKey: .single(alice.key.publicKey),
            freezeDefault: false,
            expirationTime: .now + .minutes(5),
            feeScheduleKey: .single(alice.key.publicKey),
            customFees: [.fixed(fee)]
        )
        .sign(alice.key)
        .execute(testEnv.client)
        .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = FungibleToken(id: tokenId, owner: alice)

        addTeardownBlock {
            _ = try? await token.burn(testEnv, supply: 1)
            try await token.delete(testEnv)
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenAssociateTransaction(accountId: cherry.id, tokenIds: [token.id])
            .sign(cherry.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .tokenTransfer(token.id, alice.id, -1)
            .tokenTransfer(token.id, bob.id, 1)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        addTeardownBlock {
            _ = try await TokenWipeTransaction(tokenId: token.id, amount: 1)
                .accountId(bob.id)
                .sign(alice.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        await assertThrowsHErrorAsync(
            try await TransferTransaction()
                .tokenTransfer(token.id, bob.id, -1)
                .tokenTransfer(token.id, cherry.id, 1)
                .sign(bob.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .insufficientSenderAccountBalanceForCustomFee)
        }
    }

    internal func testUnownedTokenFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let aliceFut = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)

        let (alice, bob) = try await (aliceFut, bobFut)

        let token = try await FungibleToken.create(testEnv, owner: alice, initialSupply: 10)

        addTeardownBlock {
            try await token.burn(testEnv, supply: 10)
            try await token.delete(testEnv)
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenGrantKycTransaction(accountId: bob.id, tokenId: token.id)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        // notice the swapped direction
        await assertThrowsHErrorAsync(
            try await TransferTransaction()
                .tokenTransfer(token.id, bob.id, -10)
                .tokenTransfer(token.id, alice.id, 10)
                .sign(bob.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .insufficientTokenBalance)
        }
    }

    internal func testDecimals() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let aliceFut = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)

        let (alice, bob) = try await (aliceFut, bobFut)

        let token = try await FungibleToken.create(testEnv, owner: alice, initialSupply: 10)

        addTeardownBlock {
            try await token.burn(testEnv, supply: 10)
            try await token.delete(testEnv)
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenGrantKycTransaction(accountId: bob.id, tokenId: token.id)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .tokenTransferWithDecimals(token.id, alice.id, -10, 3)
            .tokenTransferWithDecimals(token.id, bob.id, 10, 3)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TransferTransaction()
            .tokenTransferWithDecimals(token.id, bob.id, -10, 3)
            .tokenTransferWithDecimals(token.id, alice.id, 10, 3)
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testIncorrectDecimalsFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let aliceFut = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)

        let (alice, bob) = try await (aliceFut, bobFut)

        let token = try await FungibleToken.create(testEnv, owner: alice, initialSupply: 10)

        addTeardownBlock {
            try await token.burn(testEnv, supply: 10)
            try await token.delete(testEnv)
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        _ = try await TokenGrantKycTransaction(accountId: bob.id, tokenId: token.id)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        await assertThrowsHErrorAsync(
            _ = try await TransferTransaction()
                .tokenTransferWithDecimals(token.id, alice.id, -10, 2)
                .tokenTransferWithDecimals(token.id, bob.id, 10, 2)
                .sign(alice.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .unexpectedTokenDecimals)
        }
    }
}
