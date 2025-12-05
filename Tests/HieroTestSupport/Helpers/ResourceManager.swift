// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

/// Cleanup priority order for test resources.
/// Lower priority values run first during cleanup.
public enum CleanupPriority: Int {
    /// Phase 0: Unpause tokens - must happen before any token operations
    case unpauseTokens = 5

    /// Phase 1: Settle token balances - transfer tokens back to treasuries and dissociate
    case settleBalances = 10

    /// Phase 2: Delete tokens - now all accounts (including treasuries) are empty
    case tokens = 50

    /// Phase 3: Delete accounts - now accounts have no token associations
    case accounts = 70

    // Other resources (not involved in the account/token dependency chain)
    case files = 30
    case topics = 40
    case schedules = 45
    case contracts = 60
}

/// Manages test resources and ensures proper cleanup
public actor ResourceManager {
    private var accounts: [AccountId: TestAccount] = [:]
    private var contracts: [ContractId: TestContract] = [:]
    private var cleanupActions: [CleanupAction] = []

    /// Wipe keys stored by token ID for use during balance settlement
    private var wipeKeys: [TokenId: PrivateKey] = [:]

    /// Pause keys stored by token ID for use during token deletion
    private var pauseKeys: [TokenId: PrivateKey] = [:]

    private let client: Client
    private let operatorAccountId: AccountId
    private let operatorPrivateKey: PrivateKey
    private let cleanupPolicy: CleanupPolicy

    private struct CleanupAction {
        let priority: CleanupPriority
        let action: () async throws -> Void
    }

    public init(
        client: Client,
        operatorAccountId: AccountId,
        operatorPrivateKey: PrivateKey,
        cleanupPolicy: CleanupPolicy = .economical
    ) {
        self.client = client
        self.operatorAccountId = operatorAccountId
        self.operatorPrivateKey = operatorPrivateKey
        self.cleanupPolicy = cleanupPolicy
    }

    // MARK: - Contract Management

    /// Register an existing contract for automatic cleanup (single key)
    public func registerContract(_ contractId: ContractId, adminKey: PrivateKey) async {
        await registerContract(contractId, adminKeys: [adminKey])
    }

    /// Register an existing contract for automatic cleanup (multiple keys)
    public func registerContract(_ contractId: ContractId, adminKeys: [PrivateKey]) async {
        let contract = TestContract(id: contractId, keys: adminKeys)
        contracts[contractId] = contract

        if cleanupPolicy.cleanupContracts {
            await registerCleanup(priority: .contracts) {
                try await self.deleteContract(contract)
            }
        }
    }

    private func deleteContract(_ contract: TestContract) async throws {
        let transaction = ContractDeleteTransaction(contractId: contract.id)
            .transferAccountId(operatorAccountId)

        for key in contract.adminKeys {
            transaction.sign(key)
        }

        _ =
            try await transaction
            .execute(client)
            .getReceipt(client)
    }

    // MARK: - Account Management

    /// Register an existing account for automatic cleanup (single key)
    public func registerAccount(_ accountId: AccountId, key: PrivateKey) async {
        await registerAccount(accountId, keys: [key])
    }

    /// Register an existing account for automatic cleanup (multiple keys)
    public func registerAccount(_ accountId: AccountId, keys: [PrivateKey]) async {
        let account = TestAccount(id: accountId, keys: keys)
        accounts[accountId] = account

        if cleanupPolicy.cleanupAccounts {
            // Phase 1: Settle token balances - transfer tokens back to treasuries
            await registerCleanup(priority: .settleBalances) {
                try await self.settleTokenBalances(for: account)
            }

            // Phase 3: Delete accounts - after tokens are deleted
            await registerCleanup(priority: .accounts) {
                try await self.deleteAccount(account)
            }
        }
    }

    private func deleteAccount(_ account: TestAccount) async throws {
        let transaction = AccountDeleteTransaction()
            .accountId(account.id)
            .transferAccountId(operatorAccountId)

        for key in account.keys {
            transaction.sign(key)
        }

        _ =
            try await transaction
            .execute(client)
            .getReceipt(client)
        accounts.removeValue(forKey: account.id)
    }

    /// Registers a wipe key for a token to be used during balance settlement
    public func registerWipeKey(_ wipeKey: PrivateKey, for tokenId: TokenId) {
        wipeKeys[tokenId] = wipeKey
    }

    /// Registers a pause key for a token and schedules unpause during cleanup (before any other token operations)
    public func registerPauseKey(_ pauseKey: PrivateKey, for tokenId: TokenId) async {
        pauseKeys[tokenId] = pauseKey

        // Register unpause action at highest priority so it runs before balance settlement
        await registerCleanup(priority: .unpauseTokens) {
            try await self.unpauseTokenIfNeeded(tokenId)
        }
    }

    /// Unpauses a token if it's paused and we have the pause key
    public func unpauseTokenIfNeeded(_ tokenId: TokenId) async throws {
        guard let pauseKey = pauseKeys[tokenId] else { return }

        let info = try await TokenInfoQuery(tokenId: tokenId).execute(client)
        if let pausedState = info.pauseStatus, pausedState == true {
            _ = try await TokenUnpauseTransaction()
                .tokenId(tokenId)
                .sign(pauseKey)
                .execute(client)
                .getReceipt(client)
        }
    }

    /// Settles token balances for an account being cleaned up.
    /// If the token has a wipe key, it wipes the tokens. Otherwise, transfers back to treasury.
    private func settleTokenBalances(for account: TestAccount) async throws {
        let balances = try await AccountBalanceQuery(accountId: account.id).execute(client)
        let tokenBalances = balances.tokenBalances

        if tokenBalances.isEmpty {
            return
        }

        for (tokenId, rawAmount) in tokenBalances where rawAmount > 0 {
            let info = try await TokenInfoQuery(tokenId: tokenId).execute(client)

            // Skip if this account is the treasury - can't wipe or transfer to yourself
            if info.treasuryAccountId == account.id {
                continue
            }

            if info.tokenType == .nonFungibleUnique {
                // For NFTs, collect the serials owned by this account
                var ownedSerials: [UInt64] = []
                var serial: UInt64 = 1

                while UInt64(ownedSerials.count) < rawAmount {
                    let nftId = tokenId.nft(serial)
                    do {
                        let nftInfo = try await TokenNftInfoQuery().nftId(nftId).execute(client)
                        if nftInfo.accountId == account.id {
                            ownedSerials.append(serial)
                        }
                    } catch {
                        // NFT doesn't exist or other error, continue to next serial
                    }
                    serial += 1

                    // Safety limit to prevent infinite loops
                    if serial > rawAmount * 10 + 100 {
                        break
                    }
                }

                if ownedSerials.isEmpty {
                    continue
                }

                // Try to wipe if we have the wipe key stored, otherwise transfer
                if let wipeKey = wipeKeys[tokenId] {
                    _ = try await TokenWipeTransaction()
                        .tokenId(tokenId)
                        .accountId(account.id)
                        .serials(ownedSerials)
                        .sign(wipeKey)
                        .execute(client)
                        .getReceipt(client)
                } else {
                    // Transfer each NFT back to treasury
                    for ownedSerial in ownedSerials {
                        let nftId = tokenId.nft(ownedSerial)
                        let transaction = TransferTransaction()
                            .nftTransfer(nftId, account.id, info.treasuryAccountId)

                        for key in account.keys {
                            transaction.sign(key)
                        }

                        _ = try await transaction.execute(client).getReceipt(client)
                    }
                }
            } else {
                // For fungible tokens
                if let wipeKey = wipeKeys[tokenId] {
                    // Wipe the tokens from the account
                    _ = try await TokenWipeTransaction()
                        .tokenId(tokenId)
                        .accountId(account.id)
                        .amount(rawAmount)
                        .sign(wipeKey)
                        .execute(client)
                        .getReceipt(client)
                } else {
                    // Transfer the balance back to treasury
                    guard let amount = Int64(exactly: rawAmount) else {
                        print(
                            "Warning: Token balance \(rawAmount) for \(tokenId) exceeds Int64.max, skipping transfer for account \(account.id)"
                        )
                        continue
                    }

                    let transaction = TransferTransaction()
                        .tokenTransfer(tokenId, account.id, -amount)
                        .tokenTransfer(tokenId, info.treasuryAccountId, amount)

                    for key in account.keys {
                        transaction.sign(key)
                    }

                    _ = try await transaction.execute(client).getReceipt(client)
                }
            }
        }
    }

    // MARK: - Cleanup Management

    /// Register a custom cleanup action
    public func registerCleanup(priority: CleanupPriority, action: @escaping () async throws -> Void) async {
        cleanupActions.append(CleanupAction(priority: priority, action: action))
    }

    /// Execute all cleanup actions
    public func cleanup() async throws {
        // Skip cleanup if no policy is enabled
        if !cleanupPolicy.cleanupAccounts && !cleanupPolicy.cleanupTokens && !cleanupPolicy.cleanupFiles
            && !cleanupPolicy.cleanupTopics && !cleanupPolicy.cleanupContracts
        {
            print("Resource cleanup is disabled - skipping")
            return
        }

        // Sort by priority in ASCENDING order (lower priority values run first)
        // Cleanup order: unpauseTokens (5) → settleBalances (10) → files (30) → topics (40) → schedules (45) → tokens (50) → contracts (60) → accounts (70)
        let sortedActions = cleanupActions.sorted { $0.priority.rawValue < $1.priority.rawValue }

        for action in sortedActions {
            do {
                try await action.action()
            } catch {
                // Log error but continue cleanup
                print("Warning: Cleanup action failed: \(error)")
            }
        }

        cleanupActions.removeAll()
        accounts.removeAll()
        contracts.removeAll()
    }
}

// MARK: - Internal Test Resource Types

/// Internal struct for tracking accounts during cleanup
struct TestAccount {
    let id: AccountId
    let keys: [PrivateKey]

    /// Single key convenience accessor (returns first key)
    var key: PrivateKey {
        keys[0]
    }

    init(id: AccountId, key: PrivateKey) {
        self.id = id
        self.keys = [key]
    }

    init(id: AccountId, keys: [PrivateKey]) {
        precondition(!keys.isEmpty, "TestAccount requires at least one key")
        self.id = id
        self.keys = keys
    }
}

/// Internal struct for tracking contracts during cleanup
struct TestContract {
    let id: ContractId
    let adminKeys: [PrivateKey]

    /// Single key convenience accessor (returns first key)
    var adminKey: PrivateKey {
        adminKeys[0]
    }

    init(id: ContractId, key: PrivateKey) {
        self.id = id
        self.adminKeys = [key]
    }

    init(id: ContractId, keys: [PrivateKey]) {
        precondition(!keys.isEmpty, "TestContract requires at least one key")
        self.id = id
        self.adminKeys = keys
    }
}
