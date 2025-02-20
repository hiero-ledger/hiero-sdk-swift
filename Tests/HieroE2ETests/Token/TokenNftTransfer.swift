/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

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
