// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class TokenNftTransfer: XCTestCase {
    internal func testBasic() async throws {
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

        let transferTx = TransferTransaction()

        for serial in serials[..<4] {
            transferTx.nftTransfer(token.id.nft(serial), alice.id, bob.id)
        }

        _ = try await transferTx.sign(alice.key).execute(testEnv.client).getReceipt(testEnv.client)

        // just to make it sure that this is teardown code.
        addTeardownBlock {
            let transferTx = TransferTransaction()

            for serial in serials[..<4] {
                transferTx.nftTransfer(token.id.nft(serial), bob.id, alice.id)
            }

            _ = try await transferTx.sign(bob.key).execute(testEnv.client).getReceipt(testEnv.client)
        }
    }

    internal func testUnownedNftsFails() async throws {
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

        let transferTx = TransferTransaction()

        // try to transfer in the wrong direction
        for serial in serials[..<4] {
            transferTx.nftTransfer(token.id.nft(serial), bob.id, alice.id)
        }

        await assertThrowsHErrorAsync(
            try await transferTx
                .sign(bob.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client)
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .senderDoesNotOwnNftSerialNo)
        }
    }
}
