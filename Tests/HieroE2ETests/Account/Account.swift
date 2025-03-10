// SPDX-License-Identifier: Apache-2.0

import Hiero
import XCTest

internal struct Account {
    internal let id: AccountId
    internal let key: PrivateKey

    internal static func create(_ testEnv: NonfreeTestEnvironment, balance: Hbar = 0) async throws -> Self {
        let key = PrivateKey.generateEd25519()

        try await testEnv.ratelimits.accountCreate()

        let receipt = try await AccountCreateTransaction(key: .single(key.publicKey), initialBalance: balance)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let id = try XCTUnwrap(receipt.accountId)

        return Self(id: id, key: key)
    }

    internal static func create(
        _ testEnv: NonfreeTestEnvironment, _ accountKey: Key, _ maxAutomaticTokenAssociations: Int32
    ) async throws -> Self {
        let key = PrivateKey.generateEd25519()

        try await testEnv.ratelimits.accountCreate()

        let receipt = try await AccountCreateTransaction()
            .keyWithoutAlias(accountKey)
            .initialBalance(Hbar(1))
            .maxAutomaticTokenAssociations(maxAutomaticTokenAssociations)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let id = try XCTUnwrap(receipt.accountId)

        return Self(id: id, key: key)
    }

    internal func delete(_ testEnv: NonfreeTestEnvironment) async throws {
        _ = try await AccountDeleteTransaction()
            .accountId(id)
            .transferAccountId(testEnv.operator.accountId)
            .sign(key)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)
    }
}
