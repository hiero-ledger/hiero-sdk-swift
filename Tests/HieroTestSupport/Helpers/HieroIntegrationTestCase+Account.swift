// SPDX-License-Identifier: Apache-2.0

/// Account helper methods for integration tests.
///
/// This extension provides methods for creating, registering, and asserting accounts in integration tests.
/// Accounts created with `createAccount` are automatically registered for cleanup at test teardown.

import Foundation
import Hiero
import XCTest

// MARK: - Account Helpers

extension HieroIntegrationTestCase {

    // MARK: - Unmanaged Account Creation

    /// Creates an account from a transaction without registering it for cleanup.
    ///
    /// Use this when you need full control over the account lifecycle or when testing
    /// scenarios where cleanup would interfere with the test.
    ///
    /// - Parameter transaction: Pre-configured `AccountCreateTransaction` (before execute)
    /// - Returns: The created account ID
    public func createUnmanagedAccount(_ transaction: AccountCreateTransaction) async throws -> AccountId {
        let receipt = try await transaction.execute(testEnv.client).getReceipt(testEnv.client)
        return try XCTUnwrap(receipt.accountId)
    }

    // MARK: - Account Registration

    /// Registers an existing account for automatic cleanup at test teardown.
    ///
    /// - Parameters:
    ///   - accountId: The account ID to register
    ///   - key: Private key for account deletion
    public func registerAccount(_ accountId: AccountId, key: PrivateKey) async {
        await registerAccount(accountId, keys: [key])
    }

    /// Registers an existing account for automatic cleanup at test teardown (multiple keys).
    ///
    /// - Parameters:
    ///   - accountId: The account ID to register
    ///   - keys: Private keys required for account deletion
    public func registerAccount(_ accountId: AccountId, keys: [PrivateKey]) async {
        await resourceManager.registerAccount(accountId, keys: keys)
    }

    // MARK: - Managed Account Creation

    /// Creates an account and registers it for automatic cleanup.
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `AccountCreateTransaction` (before execute)
    ///   - key: Private key for account deletion
    /// - Returns: The created account ID
    public func createAccount(
        _ transaction: AccountCreateTransaction,
        key: PrivateKey
    ) async throws -> AccountId {
        try await createAccount(transaction, keys: [key])
    }

    /// Creates an account and registers it for automatic cleanup (multiple keys).
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `AccountCreateTransaction` (before execute)
    ///   - keys: Private keys required for account deletion
    /// - Returns: The created account ID
    public func createAccount(
        _ transaction: AccountCreateTransaction,
        keys: [PrivateKey]
    ) async throws -> AccountId {
        let accountId = try await createUnmanagedAccount(transaction)
        await registerAccount(accountId, keys: keys)
        return accountId
    }

    // MARK: - Convenience Account Creation

    /// Creates a test account with an Ed25519 key and optional initial balance.
    ///
    /// This is the primary convenience method for creating accounts in tests.
    ///
    /// - Parameter initialBalance: Optional initial Hbar balance. If nil, no balance is set.
    /// - Returns: Tuple of account ID and private key
    public func createTestAccount(
        initialBalance: Hbar? = nil
    ) async throws -> (accountId: AccountId, key: PrivateKey) {
        let key = PrivateKey.generateEd25519()
        var tx = AccountCreateTransaction()
            .keyWithoutAlias(.single(key.publicKey))
        if let initialBalance = initialBalance {
            tx = try tx.initialBalance(initialBalance)
                .freezeWith(testEnv.client)
                .sign(key)
        }
        let accountId = try await createAccount(tx, key: key)
        return (accountId, key)
    }

    /// Creates an unmanaged account with an Ed25519 key and optional initial balance.
    ///
    /// Use this when you need an account that won't be automatically cleaned up.
    ///
    /// - Parameter initialBalance: Optional initial Hbar balance
    /// - Returns: Tuple of account ID and private key
    public func createSimpleUnmanagedAccount(
        initialBalance: Hbar? = nil
    ) async throws -> (accountId: AccountId, key: PrivateKey) {
        let key = PrivateKey.generateEd25519()
        var tx = AccountCreateTransaction().keyWithoutAlias(.single(key.publicKey))
        if let initialBalance = initialBalance {
            tx = tx.initialBalance(initialBalance)
        }
        let accountId = try await createUnmanagedAccount(tx)
        return (accountId, key)
    }

    // MARK: - Key Generation Helpers

    /// Creates an ECDSA key pair and extracts the EVM address.
    ///
    /// Useful for tests involving EVM address functionality.
    ///
    /// - Returns: Tuple of private key and EVM address
    public func generateEcdsaKeyWithEvmAddress() throws -> (key: PrivateKey, evmAddress: EvmAddress) {
        let key = PrivateKey.generateEcdsa()
        let evmAddress = try XCTUnwrap(key.publicKey.toEvmAddress())
        return (key, evmAddress)
    }

    /// Checks if an EVM address is a zero address (all first 12 bytes are zero).
    ///
    /// - Parameter address: The address bytes to check
    /// - Returns: True if it's a zero address
    public func isZeroEvmAddress(_ address: [UInt8]) -> Bool {
        for byte in address[..<12] where byte != 0 {
            return false
        }
        return true
    }

    // MARK: - AccountInfo Assertions

    /// Asserts basic account info properties.
    ///
    /// - Parameters:
    ///   - info: Account info to validate
    ///   - accountId: Expected account ID
    ///   - key: Expected account key
    ///   - isDeleted: Expected deletion status (default: false)
    public func assertAccountInfo(
        _ info: AccountInfo,
        accountId: AccountId,
        key: Key,
        isDeleted: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(info.accountId, accountId, "Account ID mismatch", file: file, line: line)
        XCTAssertEqual(info.isDeleted, isDeleted, "isDeleted mismatch", file: file, line: line)
        XCTAssertEqual(info.key, key, "Key mismatch", file: file, line: line)
    }

    /// Asserts account info with EVM address validation.
    ///
    /// - Parameters:
    ///   - info: Account info to validate
    ///   - accountId: Expected account ID
    ///   - key: Expected account key
    ///   - evmAddress: Expected EVM address
    public func assertAccountInfoWithEvmAddress(
        _ info: AccountInfo,
        accountId: AccountId,
        key: Key,
        evmAddress: EvmAddress,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(info.accountId, accountId, "Account ID mismatch", file: file, line: line)
        XCTAssertEqual(info.key, key, "Key mismatch", file: file, line: line)
        XCTAssertEqual(
            "0x\(info.contractAccountId)", evmAddress.toString(),
            "EVM address mismatch", file: file, line: line
        )
    }

    /// Asserts that account info contains an EVM address in contractAccountId.
    ///
    /// - Parameters:
    ///   - info: Account info to validate
    ///   - evmAddress: EVM address that should be contained
    public func assertAccountInfoContainsEvmAddress(
        _ info: AccountInfo,
        evmAddress: EvmAddress,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            evmAddress.toString().contains(info.contractAccountId),
            "contractAccountId should contain EVM address", file: file, line: line
        )
    }

    // MARK: - AccountBalance Assertions

    /// Asserts account balance properties.
    ///
    /// - Parameters:
    ///   - balance: Account balance to validate
    ///   - accountId: Expected account ID
    ///   - hasPositiveBalance: Whether to assert positive balance (default: true)
    public func assertAccountBalance(
        _ balance: AccountBalance,
        accountId: AccountId,
        hasPositiveBalance: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(balance.accountId, accountId, "Account ID mismatch", file: file, line: line)
        if hasPositiveBalance {
            XCTAssertGreaterThan(balance.hbars, 0, "Expected positive hbar balance", file: file, line: line)
        }
    }
}
