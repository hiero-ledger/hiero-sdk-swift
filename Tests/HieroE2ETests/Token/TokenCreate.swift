// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal final class TokenCreate: XCTestCase {
    internal func testAllOperatorKeys() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .decimals(3)
            .initialSupply(0)
            .expirationTime(.now + .minutes(5))
            .treasuryAccountId(account.id)
            .adminKey(.single(account.key.publicKey))
            .freezeKey(.single(account.key.publicKey))
            .wipeKey(.single(account.key.publicKey))
            .kycKey(.single(account.key.publicKey))
            .supplyKey(.single(account.key.publicKey))
            .feeScheduleKey(.single(account.key.publicKey))
            .freezeDefault(false)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = FungibleToken(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }
    }

    internal func testMinimalProperties() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await Account.create(testEnv)

        _ = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .treasuryAccountId(account.id)
            .expirationTime(.now + .minutes(5))
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }

    internal func testMissingNameFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        await assertThrowsHErrorAsync(
            try await TokenCreateTransaction()
                .symbol("F")
                .treasuryAccountId(account.id)
                .expirationTime(.now + .minutes(5))
                .sign(account.key).execute(testEnv.client).getReceipt(testEnv.client),
            "expected error creating token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }

            XCTAssertEqual(status, .missingTokenName)
        }
    }

    internal func testMissingSymbolFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        await assertThrowsHErrorAsync(
            try await TokenCreateTransaction()
                .name("ffff")
                .treasuryAccountId(account.id)
                .expirationTime(.now + .minutes(5))
                .sign(account.key).execute(testEnv.client).getReceipt(testEnv.client),
            "expected error creating token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `receiptStatus`")
                return
            }

            XCTAssertEqual(status, .missingTokenSymbol)
        }
    }

    internal func testMissingTreasuryAccountIdFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        await assertThrowsHErrorAsync(
            try await TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .expirationTime(.now + .minutes(5))
                .sign(account.key)
                .execute(testEnv.client),
            "expected error creating token"
        ) { error in
            guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.transactionPreCheckStatus`")
                return
            }
            XCTAssertEqual(status, .invalidTreasuryAccountForToken)
        }
    }

    internal func disabled_testMissingTreasuryAccountIdSigFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        await assertThrowsHErrorAsync(
            try await TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(AccountId(num: 3))
                .expirationTime(.now + .minutes(5))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }
            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testAdminKeySigFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let adminKey = PrivateKey.generateEd25519()

        await assertThrowsHErrorAsync(
            try await TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(account.id)
                .adminKey(.single(adminKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }
            XCTAssertEqual(status, .invalidSignature)
        }
    }

    internal func testCustomFees() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let customFees: [AnyCustomFee] = [
            .fixed(.init(amount: 11, feeCollectorAccountId: account.id)),
            .fractional(.init(amount: "1/20", minimumAmount: 1, maximumAmount: 10, feeCollectorAccountId: account.id)),
        ]

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .treasuryAccountId(account.id)
            .adminKey(.single(account.key.publicKey))
            .customFees(customFees)
            .expirationTime(.now + .minutes(5))
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = FungibleToken(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }
    }

    internal func testTooManyCustomFeesFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let customFees: [AnyCustomFee] = Array(
            repeating: .fixed(.init(amount: 10, feeCollectorAccountId: account.id)), count: 11)

        await assertThrowsHErrorAsync(
            try await TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(account.id)
                .adminKey(.single(account.key.publicKey))
                .customFees(customFees)
                .expirationTime(.now + .minutes(5))
                .sign(account.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }
            XCTAssertEqual(status, .customFeesListTooLong)
        }
    }

    internal func testTenFixedFees() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let customFees: [AnyCustomFee] = Array(
            repeating: .fixed(.init(amount: 10, feeCollectorAccountId: account.id)), count: 10)

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .treasuryAccountId(account.id)
            .adminKey(.single(account.key.publicKey))
            .customFees(customFees)
            .expirationTime(.now + .minutes(5))
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = FungibleToken(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }
    }

    internal func testTenFractionalFees() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let customFees: [AnyCustomFee] = Array(
            repeating: .fractional(
                .init(amount: "1/20", minimumAmount: 1, maximumAmount: 10, feeCollectorAccountId: account.id)),
            count: 10)

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .treasuryAccountId(account.id)
            .adminKey(.single(account.key.publicKey))
            .customFees(customFees)
            .expirationTime(.now + .minutes(5))
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = FungibleToken(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }
    }

    internal func testFractionalFeeMinBiggerThanMaxFail() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let customFees: [AnyCustomFee] = [
            .fractional(.init(amount: "1/3", minimumAmount: 3, maximumAmount: 2, feeCollectorAccountId: account.id))
        ]

        await assertThrowsHErrorAsync(
            try await TokenCreateTransaction()
                .name("ffff")
                .symbol("F")
                .treasuryAccountId(account.id)
                .adminKey(.single(account.key.publicKey))
                .customFees(customFees)
                .expirationTime(.now + .minutes(5))
                .sign(account.key)
                .execute(testEnv.client)
                .getReceipt(testEnv.client),
            "expected error creating token"
        ) { error in
            guard case .receiptStatus(let status, transactionId: _) = error.kind else {
                XCTFail("`\(error.kind)` is not `.receiptStatus`")
                return
            }
            XCTAssertEqual(status, .fractionalFeeMaxAmountLessThanMinAmount)
        }
    }

    internal func testNfts() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .tokenType(TokenType.nonFungibleUnique)
            .expirationTime(.now + .minutes(5))
            .treasuryAccountId(account.id)
            .adminKey(.single(account.key.publicKey))
            .freezeKey(.single(account.key.publicKey))
            .wipeKey(.single(account.key.publicKey))
            .kycKey(.single(account.key.publicKey))
            .supplyKey(.single(account.key.publicKey))
            .freezeDefault(false)
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = Nft(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }
    }

    internal func testRoyalFee() async throws {
        let testEnv = try TestEnvironment.nonFree

        let account = try await makeAccount(testEnv)

        let customFees: [AnyCustomFee] = [
            .royalty(
                .init(
                    exchangeValue: "1/10", fallbackFee: FixedFee(amount: 1), feeCollectorAccountId: account.id,
                    allCollectorsAreExempt: false))
        ]

        let receipt = try await TokenCreateTransaction()
            .name("ffff")
            .symbol("F")
            .customFees(customFees)
            .tokenType(TokenType.nonFungibleUnique)
            .expirationTime(.now + .minutes(5))
            .treasuryAccountId(account.id)
            .adminKey(.single(account.key.publicKey))
            .supplyKey(.single(account.key.publicKey))
            .sign(account.key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let tokenId = try XCTUnwrap(receipt.tokenId)

        let token = Nft(id: tokenId, owner: account)

        addTeardownBlock {
            try await token.delete(testEnv)
        }
    }
}
