// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class TokenWipe: XCTestCase {
    internal func testFungible() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let alice = makeAccount(testEnv)
        async let bob = makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: alice, initialSupply: 10)

        addTeardownBlock {
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

        _ = try await TokenWipeTransaction(tokenId: token.id, amount: 10)
            .accountId(bob.id)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testNft() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let aliceFut = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)

        let (alice, bob) = try await (aliceFut, bobFut)
        let token = try await Nft.create(testEnv, owner: alice)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let serials = try await token.mint(testEnv, count: 10)

        let transferTx = TransferTransaction()

        for serial in serials {
            transferTx.nftTransfer(token.id.nft(serial), alice.id, bob.id)
        }

        _ = try await transferTx.sign(alice.key).execute(testEnv.client).getReceipt(testEnv.client)

        _ = try await TokenWipeTransaction(tokenId: token.id, serials: serials)
            .accountId(bob.id)
            .sign(alice.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testUnownedNftFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let aliceFut = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)

        let (alice, bob) = try await (aliceFut, bobFut)
        let token = try await Nft.create(testEnv, owner: alice)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        _ = try await TokenAssociateTransaction(accountId: bob.id, tokenIds: [token.id])
            .sign(bob.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let serials = try await token.mint(testEnv, count: 10)

        addTeardownBlock {
            try await token.burn(testEnv, serials: serials)
        }

        // don't transfer them
        await assertThrowsHErrorAsync(
            try await TokenWipeTransaction(tokenId: token.id, serials: serials)
                .accountId(bob.id)
                .sign(alice.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .accountDoesNotOwnWipedNft)
        }
    }

    internal func testMissingAccountIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await TokenWipeTransaction(tokenId: token.id, amount: 10).execute(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidAccountID)
        }
    }

    internal func testMissingTokenIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenWipeTransaction(amount: 10)
                .accountId(testEnv.operator.accountId)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidTokenID)
        }
    }

    internal func testMissingAmount() async throws {
        let testEnv = try TestEnvironment.nonFree

        async let aliceFut = makeAccount(testEnv)
        async let bobFut = makeAccount(testEnv)

        let (alice, bob) = try await (aliceFut, bobFut)

        let token = try await FungibleToken.create(testEnv, owner: alice, initialSupply: 10)

        addTeardownBlock {
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

        addTeardownBlock {
            // this is just so that we can actually delete the token.
            _ = try await TokenWipeTransaction(tokenId: token.id, amount: 10)
                .accountId(bob.id)
                .sign(alice.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        }

        // this is the CUT
        _ = try await TokenWipeTransaction(tokenId: token.id)
            .accountId(bob.id)
            .sign(alice.key)
            .execute(testEnv.client)
    }
}
