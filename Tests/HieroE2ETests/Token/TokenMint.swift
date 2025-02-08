// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal class TokenMint: XCTestCase {
    internal func testBasic() async throws {
        let initialSupply: UInt64 = 1_000_000

        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account, initialSupply: initialSupply)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let receipt = try await TokenMintTransaction(tokenId: token.id, amount: 10)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        addTeardownBlock {
            try await token.burn(testEnv, supply: initialSupply + 10)
        }

        XCTAssertEqual(receipt.totalSupply, initialSupply + 10)
    }

    internal func testOverSupplyLimitFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let receipt = try await TokenCreateTransaction(
            name: "ffff",
            symbol: "F",
            treasuryAccountId: account.id,
            adminKey: .single(account.key.publicKey),
            supplyKey: .single(account.key.publicKey),
            expirationTime: .now + .minutes(5),
            tokenSupplyType: .finite, maxSupply: 5
        )
        .sign(account.key)
        .execute(testEnv.client)
        .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = FungibleToken(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await TokenMintTransaction(tokenId: token.id, amount: 6)
                .sign(account.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error minting token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .tokenMaxSupplyReached)
        }
    }

    internal func testMissingTokenIdFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenMintTransaction(amount: 6).execute(testEnv.client),
            "expected error minting token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .invalidTokenID)
        }
    }

    internal func testZero() async throws {
        let initialSupply: UInt64 = 1_000_000
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account, initialSupply: initialSupply)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let receipt = try await TokenMintTransaction(tokenId: token.id, amount: 0)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        addTeardownBlock {
            try await token.burn(testEnv, supply: initialSupply)
        }

        XCTAssertEqual(receipt.totalSupply, initialSupply)
    }

    internal func testMissingSupplyKeySigFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await TokenMintTransaction(tokenId: token.id, amount: 10)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error minting token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testNfts() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let receipt = try await TokenCreateTransaction(
            name: "ffff",
            symbol: "F",
            treasuryAccountId: account.id,
            adminKey: .single(account.key.publicKey),
            supplyKey: .single(account.key.publicKey),
            expirationTime: .now + .minutes(5),
            tokenType: .nonFungibleUnique,
            tokenSupplyType: .finite,
            maxSupply: 5000
        )
        .sign(account.key)
        .execute(testEnv.client)
        .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = Nft(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let mintReceipt = try await TokenMintTransaction(tokenId: token.id, metadata: (0..<10).map { Data([$0]) })
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let serials = try XCTUnwrap(mintReceipt.serials)

        addTeardownBlock {
            try await token.burn(testEnv, serials: serials)
        }
    }

    internal func testNftMetadataTooLongFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let receipt = try await TokenCreateTransaction(
            name: "ffff",
            symbol: "F",
            treasuryAccountId: account.id,
            adminKey: .single(account.key.publicKey),
            supplyKey: .single(account.key.publicKey),
            expirationTime: .now + .minutes(5),
            tokenType: .nonFungibleUnique,
            tokenSupplyType: .finite,
            maxSupply: 5000
        )
        .sign(account.key)
        .execute(testEnv.client)
        .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = Nft(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await TokenMintTransaction(tokenId: token.id, metadata: [Data(repeating: 1, count: 101)])
                .sign(account.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error minting token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .metadataTooLong)
        }
    }
}
