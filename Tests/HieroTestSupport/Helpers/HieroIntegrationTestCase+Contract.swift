// SPDX-License-Identifier: Apache-2.0

/// Contract helper methods for integration tests.
///
/// This extension provides methods for creating, registering, and asserting smart contracts in integration tests.
/// Contracts created with `createContract` are automatically registered for cleanup at test teardown.

import Foundation
import Hiero
import XCTest

// MARK: - Contract Helpers

extension HieroIntegrationTestCase {

    // MARK: - Unmanaged Contract Creation

    /// Creates a smart contract from a transaction without registering it for cleanup.
    ///
    /// Use this when you need full control over the contract lifecycle or when testing
    /// scenarios where cleanup would interfere with the test (e.g., immutable contracts).
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `ContractCreateTransaction` (before execute)
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created contract ID
    public func createUnmanagedContract(_ transaction: ContractCreateTransaction, useAdminClient: Bool = false)
        async throws -> ContractId
    {
        let receipt =
            try await transaction
            .execute(useAdminClient ? testEnv.adminClient : testEnv.client)
            .getReceipt(useAdminClient ? testEnv.adminClient : testEnv.client)
        return try XCTUnwrap(receipt.contractId)
    }

    // MARK: - Contract Registration

    /// Registers an existing contract for automatic cleanup at test teardown.
    ///
    /// - Parameters:
    ///   - contractId: The contract ID to register
    ///   - adminKey: Private key for contract deletion
    public func registerContract(
        _ contractId: ContractId,
        adminKey: PrivateKey
    ) async {
        await registerContract(contractId, adminKeys: [adminKey])
    }

    /// Registers an existing contract for automatic cleanup at test teardown (multiple keys).
    ///
    /// - Parameters:
    ///   - contractId: The contract ID to register
    ///   - adminKeys: Private keys required for contract deletion
    public func registerContract(
        _ contractId: ContractId,
        adminKeys: [PrivateKey]
    ) async {
        await resourceManager.registerContract(contractId, adminKeys: adminKeys)
    }

    // MARK: - Managed Contract Creation

    /// Creates a smart contract and registers it for automatic cleanup.
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `ContractCreateTransaction` (before execute)
    ///   - adminKey: Private key for contract deletion
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created contract ID
    public func createContract(
        _ transaction: ContractCreateTransaction,
        adminKey: PrivateKey,
        useAdminClient: Bool = false
    ) async throws -> ContractId {
        try await createContract(transaction, adminKeys: [adminKey], useAdminClient: useAdminClient)
    }

    /// Creates a smart contract and registers it for automatic cleanup (multiple keys).
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `ContractCreateTransaction` (before execute)
    ///   - adminKeys: Private keys required for contract deletion
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created contract ID
    public func createContract(
        _ transaction: ContractCreateTransaction,
        adminKeys: [PrivateKey],
        useAdminClient: Bool = false
    ) async throws -> ContractId {
        let contractId = try await createUnmanagedContract(transaction, useAdminClient: useAdminClient)
        await registerContract(contractId, adminKeys: adminKeys)
        return contractId
    }

    // MARK: - Bytecode File Creation

    /// Creates a file with standard contract bytecode for testing.
    ///
    /// The file is automatically registered for cleanup.
    ///
    /// - Parameter useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created file ID
    public func createContractBytecodeFile(useAdminClient: Bool = false) async throws -> FileId {
        try await createFile(
            FileCreateTransaction()
                .keys([.single(testEnv.operator.privateKey.publicKey)])
                .contents(TestConstants.contractBytecode),
            key: testEnv.operator.privateKey,
            useAdminClient: useAdminClient
        )
    }

    // MARK: - Convenience Contract Creation

    /// Creates a standard contract creation transaction with default values.
    ///
    /// This creates the transaction but does not execute it. Useful for tests
    /// that need to customize the contract before creation.
    ///
    /// - Parameters:
    ///   - fileId: File ID containing contract bytecode
    ///   - adminKey: Admin key configuration:
    ///     - `nil` (default): Uses operator's public key
    ///     - `.some(.none)`: No admin key (immutable contract)
    ///     - `.some(.some(key))`: Use specified key
    ///   - gas: Gas amount (default: TestConstants.standardContractGas)
    /// - Returns: A configured `ContractCreateTransaction`
    public func standardContractCreateTransaction(
        fileId: FileId,
        adminKey: PublicKey?? = nil,
        gas: UInt64? = nil
    ) -> ContractCreateTransaction {
        var transaction = ContractCreateTransaction()
            .gas(gas ?? TestConstants.standardContractGas)
            .constructorParameters(TestConstants.standardContractConstructorParameters())
            .bytecodeFileId(fileId)

        switch adminKey {
        case .none:
            // Parameter not provided - use default (operator's key)
            transaction = transaction.adminKey(.single(testEnv.operator.privateKey.publicKey))
        case .some(.none):
            // Explicitly nil - no admin key (immutable contract)
            break
        case .some(.some(let key)):
            // Explicitly provided key
            transaction = transaction.adminKey(.single(key))
        }

        return transaction
    }

    /// Creates a contract with standard configuration.
    ///
    /// Uses operator's admin key, standard gas, and is registered for cleanup.
    /// For custom configurations, use `standardContractCreateTransaction` with
    /// `createContract` or `createUnmanagedContract` directly.
    ///
    /// - Parameter useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created contract ID
    public func createStandardContract(useAdminClient: Bool = false) async throws -> ContractId {
        let fileId = try await createContractBytecodeFile(useAdminClient: useAdminClient)
        let transaction = standardContractCreateTransaction(fileId: fileId)
        return try await createContract(
            transaction, adminKey: testEnv.operator.privateKey, useAdminClient: useAdminClient)
    }

    /// Creates an immutable contract (no admin key, cannot be deleted).
    ///
    /// Note: This creates an unmanaged contract since immutable contracts cannot be cleaned up.
    ///
    /// - Parameter useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created contract ID
    public func createImmutableContract(useAdminClient: Bool = false) async throws -> ContractId {
        let fileId = try await createContractBytecodeFile(useAdminClient: useAdminClient)
        return try await createUnmanagedContract(
            standardContractCreateTransaction(fileId: fileId, adminKey: .some(.none)),
            useAdminClient: useAdminClient
        )
    }

    /// Creates an unmanaged contract with the operator's admin key.
    ///
    /// - Parameter useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created contract ID
    public func createUnmanagedContractWithOperatorAdmin(useAdminClient: Bool = false) async throws -> ContractId {
        let fileId = try await createContractBytecodeFile(useAdminClient: useAdminClient)
        return try await createUnmanagedContract(
            standardContractCreateTransaction(
                fileId: fileId,
                adminKey: testEnv.operator.privateKey.publicKey
            ),
            useAdminClient: useAdminClient
        )
    }

    // MARK: - ContractCreateFlow Helpers

    /// Creates a standard ContractCreateFlow with default configuration.
    ///
    /// This is useful for tests that need to use the flow API instead of
    /// creating bytecode files separately.
    ///
    /// - Parameter adminKey: Admin key for the contract
    /// - Returns: A configured `ContractCreateFlow`
    public func standardContractCreateFlow(adminKey: Key) -> ContractCreateFlow {
        ContractCreateFlow()
            .bytecode(TestConstants.contractBytecode)
            .adminKey(adminKey)
            .gas(TestConstants.standardContractGas)
            .constructorParameters(TestConstants.standardContractConstructorParameters())
    }

    // MARK: - ContractInfo Assertions

    /// Asserts standard contract info properties.
    ///
    /// - Parameters:
    ///   - info: Contract info to validate
    ///   - contractId: Expected contract ID
    ///   - adminKey: Expected admin key
    ///   - storage: Expected storage amount (default: 128)
    public func assertStandardContractInfo(
        _ info: ContractInfo,
        contractId: ContractId,
        adminKey: Key,
        storage: UInt64 = 128
    ) {
        XCTAssertEqual(info.contractId, contractId)
        XCTAssertEqual(String(describing: info.accountId), String(describing: info.contractId))
        XCTAssertEqual(info.adminKey, adminKey)
        XCTAssertEqual(info.storage, storage)
    }

    /// Asserts immutable contract info properties.
    ///
    /// For immutable contracts, the admin key is set to the contract ID itself.
    ///
    /// - Parameters:
    ///   - info: Contract info to validate
    ///   - contractId: Expected contract ID
    ///   - storage: Expected storage amount (default: 128)
    public func assertImmutableContractInfo(
        _ info: ContractInfo,
        contractId: ContractId,
        storage: UInt64 = 128,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(info.contractId, contractId, "Contract ID mismatch", file: file, line: line)
        XCTAssertEqual(
            String(describing: info.accountId), String(describing: info.contractId),
            "Account ID should match contract ID", file: file, line: line
        )
        XCTAssertEqual(
            info.adminKey, .contractId(contractId), "Admin key should be contract ID", file: file, line: line)
        XCTAssertEqual(info.storage, storage, "Storage mismatch", file: file, line: line)
    }
}
