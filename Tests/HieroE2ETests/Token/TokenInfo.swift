// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class TokenInfo: XCTestCase {
    internal func testQueryAllDifferentKeys() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let key2 = PrivateKey.generateEd25519()
        let key3 = PrivateKey.generateEd25519()
        let key4 = PrivateKey.generateEd25519()
        let key5 = PrivateKey.generateEd25519()

        let receipt = try await TokenCreateTransaction(
            name: "ffff",
            symbol: "F",
            decimals: 3,
            initialSupply: 0,
            treasuryAccountId: account.id,
            adminKey: .single(account.key.publicKey),
            kycKey: .single(key4.publicKey),
            freezeKey: .single(key2.publicKey),
            wipeKey: .single(key3.publicKey),
            supplyKey: .single(key5.publicKey),
            freezeDefault: false,
            expirationTime: .now + .minutes(5)
        )
        .sign(account.key)
        .execute(testEnv.client)
        .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = FungibleToken(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let info = try await TokenInfoQuery(tokenId: token.id).execute(testEnv.client)

        XCTAssertEqual(info.tokenId, token.id)
        XCTAssertEqual(info.name, "ffff")
        XCTAssertEqual(info.symbol, "F")
        XCTAssertEqual(info.decimals, 3)
        XCTAssertEqual(info.treasuryAccountId, account.id)
        XCTAssertEqual(info.adminKey, .single(account.key.publicKey))
        XCTAssertEqual(info.freezeKey, .single(key2.publicKey))
        XCTAssertEqual(info.wipeKey, .single(key3.publicKey))
        XCTAssertEqual(info.kycKey, .single(key4.publicKey))
        XCTAssertEqual(info.supplyKey, .single(key5.publicKey))
        XCTAssertEqual(info.defaultFreezeStatus, false)
        XCTAssertEqual(info.defaultKycStatus, false)
        XCTAssertEqual(info.tokenType, .fungibleCommon)
        XCTAssertEqual(info.supplyType, .infinite)
    }

    internal func testQueryMinimal() async throws {
        let testEnv = try TestEnvironment.nonFree

        // can't delete this account, since it's a treasury.
        let account = try await Account.create(testEnv)

        let receipt = try await TokenCreateTransaction(
            name: "ffff",
            symbol: "F",
            treasuryAccountId: account.id,
            expirationTime: .now + .minutes(5)
        )
        .sign(account.key)
        .execute(testEnv.client)
        .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let info = try await TokenInfoQuery(tokenId: tokenId).execute(testEnv.client)

        XCTAssertEqual(info.tokenId, tokenId)
        XCTAssertEqual(info.name, "ffff")
        XCTAssertEqual(info.symbol, "F")
        XCTAssertEqual(info.decimals, 0)
        XCTAssertEqual(info.treasuryAccountId, account.id)
        XCTAssertNil(info.adminKey)
        XCTAssertNil(info.freezeKey)
        XCTAssertNil(info.wipeKey)
        XCTAssertNil(info.kycKey)
        XCTAssertNil(info.supplyKey)
        XCTAssertNil(info.defaultFreezeStatus)
        XCTAssertNil(info.defaultKycStatus)
        XCTAssertEqual(info.tokenType, .fungibleCommon)
        XCTAssertEqual(info.supplyType, .infinite)
    }

    internal func testQueryNft() async throws {
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

        let serials = try await token.mint(testEnv, count: 10)

        addTeardownBlock {
            try await token.burn(testEnv, serials: serials)
        }

        XCTAssertEqual(serials.count, 10)

        let info = try await TokenInfoQuery(tokenId: token.id).execute(testEnv.client)

        XCTAssertEqual(info.tokenId, token.id)

        XCTAssertEqual(info.name, "ffff")
        XCTAssertEqual(info.symbol, "F")
        XCTAssertEqual(info.decimals, 0)
        XCTAssertEqual(info.totalSupply, 10)
        XCTAssertEqual(info.treasuryAccountId, account.id)
        XCTAssertEqual(info.adminKey, .single(account.key.publicKey))
        XCTAssertEqual(info.supplyKey, .single(account.key.publicKey))
        XCTAssertNil(info.defaultFreezeStatus)
        XCTAssertNil(info.defaultKycStatus)
        XCTAssertEqual(info.tokenType, .nonFungibleUnique)
        XCTAssertEqual(info.supplyType, .finite)
        XCTAssertEqual(info.maxSupply, 5000)
    }

    internal func testQueryCost() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)
        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let query = TokenInfoQuery(tokenId: token.id)

        let cost = try await query.getCost(testEnv.client)

        try await _ = query.paymentAmount(cost).execute(testEnv.client)
    }

    internal func testQueryCostBigMax() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)
        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let query = TokenInfoQuery(tokenId: token.id).maxPaymentAmount(Hbar(1000))

        let cost = try await query.getCost(testEnv.client)

        try await _ = query.paymentAmount(cost).execute(testEnv.client)
    }

    internal func testQueryCostSmallMaxFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)
        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        let query = TokenInfoQuery(tokenId: token.id).maxPaymentAmount(.fromTinybars(1))

        let cost = try await query.getCost(testEnv.client)

        await assertThrowsHErrorAsync(
            try await query.execute(testEnv.client),
            "expected error querying token info"
        ) { error in
            // note: there's a very small chance this fails if the cost of a ContractInfoQuery changes right when we execute it.
            XCTAssertEqual(error.kind, .maxQueryPaymentExceeded(queryCost: cost, maxQueryPayment: .fromTinybars(1)))
        }
    }

    internal func testQueryCostInsufficientTxFeeFails() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)
        let token = try await FungibleToken.create(testEnv, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }

        await assertThrowsHErrorAsync(
            try await TokenInfoQuery(tokenId: token.id)
                .maxPaymentAmount(.fromTinybars(10000))
                .paymentAmount(.fromTinybars(1))
                .execute(testEnv.client)
        ) { error in
            guard case .queryPaymentPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.queryPaymentPreCheckStatus`")
                return
            }

            XCTAssertEqual(status, .insufficientTxFee)
        }
    }
}
