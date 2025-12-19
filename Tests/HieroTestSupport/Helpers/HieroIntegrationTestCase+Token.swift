// SPDX-License-Identifier: Apache-2.0

/// Token helper methods for integration tests.
///
/// This extension provides methods for creating, registering, and asserting tokens in integration tests.
/// Tokens created with `createToken` are automatically registered for cleanup at test teardown.

import Foundation
import Hiero
import XCTest

// MARK: - Token Helpers

extension HieroIntegrationTestCase {

    // MARK: - Unmanaged Token Creation

    /// Creates a token from a transaction without registering it for cleanup.
    ///
    /// Use this when you need full control over the token lifecycle or when testing
    /// scenarios where cleanup would interfere with the test.
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `TokenCreateTransaction` (before execute)
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created token ID
    public func createUnmanagedToken(_ transaction: TokenCreateTransaction, useAdminClient: Bool = false) async throws
        -> TokenId
    {
        let receipt =
            try await transaction
            .execute(useAdminClient ? testEnv.adminClient : testEnv.client)
            .getReceipt(useAdminClient ? testEnv.adminClient : testEnv.client)
        return try XCTUnwrap(receipt.tokenId)
    }

    // MARK: - Token Registration

    /// Registers an existing token for automatic cleanup at test teardown.
    ///
    /// - Parameters:
    ///   - tokenId: The token ID to register
    ///   - adminKey: Private key for token deletion
    ///   - supplyKey: Optional key for burning tokens before deletion
    ///   - wipeKey: Optional key for wiping tokens from accounts
    ///   - pauseKey: Optional key for unpausing tokens before deletion
    ///   - useAdminClient: Whether to use the admin client (default: false)
    public func registerToken(
        _ tokenId: TokenId,
        adminKey: PrivateKey,
        supplyKey: PrivateKey? = nil,
        wipeKey: PrivateKey? = nil,
        pauseKey: PrivateKey? = nil,
        useAdminClient: Bool = false
    ) async {
        await registerToken(
            tokenId, adminKeys: [adminKey], supplyKey: supplyKey, wipeKey: wipeKey, pauseKey: pauseKey,
            useAdminClient: useAdminClient)
    }

    /// Registers an existing token for automatic cleanup at test teardown (multiple admin keys).
    ///
    /// - Parameters:
    ///   - tokenId: The token ID to register
    ///   - adminKeys: Private keys required for token deletion
    ///   - supplyKey: Optional key for burning tokens before deletion
    ///   - wipeKey: Optional key for wiping tokens from accounts
    ///   - pauseKey: Optional key for unpausing tokens before deletion
    ///   - useAdminClient: Whether to use the admin client (default: false)
    public func registerToken(
        _ tokenId: TokenId,
        adminKeys: [PrivateKey],
        supplyKey: PrivateKey? = nil,
        wipeKey: PrivateKey? = nil,
        pauseKey: PrivateKey? = nil,
        useAdminClient: Bool = false
    ) async {
        if let wipeKey = wipeKey {
            await resourceManager.registerWipeKey(wipeKey, for: tokenId)
        }
        if let pauseKey = pauseKey {
            await resourceManager.registerPauseKey(pauseKey, for: tokenId)
        }

        await resourceManager.registerCleanup(priority: .tokens) {
            [client = useAdminClient ? testEnv.adminClient : testEnv.client] in
            try await Self.cleanupToken(
                tokenId: tokenId,
                adminKeys: adminKeys,
                supplyKey: supplyKey,
                wipeKey: wipeKey,
                client: client
            )
        }
    }

    // MARK: - Managed Token Creation

    /// Creates a token and registers it for automatic cleanup.
    ///
    /// This method auto-generates cleanup-essential keys (admin, supply, wipe) if not provided.
    /// If you provide a key, it's assumed you've already attached it to the transaction.
    /// If you don't provide a key, this method generates one, attaches it, and signs.
    ///
    /// - Parameters:
    ///   - transaction: Pre-configured `TokenCreateTransaction` (before execute)
    ///   - adminKey: Admin key for deletion. If nil, auto-generated.
    ///   - supplyKey: Supply key for burning. If nil, auto-generated.
    ///   - wipeKey: Wipe key for cleanup. If nil, auto-generated.
    ///   - pauseKey: Pause key. If nil, token won't have pause capability.
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created token ID
    public func createToken(
        _ transaction: TokenCreateTransaction,
        adminKey: PrivateKey? = nil,
        supplyKey: PrivateKey? = nil,
        wipeKey: PrivateKey? = nil,
        pauseKey: PrivateKey? = nil,
        useAdminClient: Bool = false
    ) async throws -> TokenId {
        var tx = transaction

        // Auto-generate keys if not provided
        let effectiveAdminKey = adminKey ?? PrivateKey.generateEd25519()
        if adminKey == nil {
            tx = tx.adminKey(.single(effectiveAdminKey.publicKey))
        }

        let effectiveSupplyKey = supplyKey ?? PrivateKey.generateEd25519()
        if supplyKey == nil {
            tx = tx.supplyKey(.single(effectiveSupplyKey.publicKey))
        }

        let effectiveWipeKey = wipeKey ?? PrivateKey.generateEd25519()
        if wipeKey == nil {
            tx = tx.wipeKey(.single(effectiveWipeKey.publicKey))
        }

        // Sign with admin key if we generated it
        if adminKey == nil {
            tx = tx.sign(effectiveAdminKey)
        }

        let tokenId = try await createUnmanagedToken(tx, useAdminClient: useAdminClient)
        await registerToken(
            tokenId,
            adminKey: effectiveAdminKey,
            supplyKey: effectiveSupplyKey,
            wipeKey: effectiveWipeKey,
            pauseKey: pauseKey
        )

        return tokenId
    }

    // MARK: - Convenience Token Creation

    /// Creates a basic fungible token with the given treasury.
    ///
    /// - Parameters:
    ///   - treasuryAccountId: Account to receive initial supply
    ///   - treasuryKey: Key to sign the transaction
    ///   - initialSupply: Initial token supply (default: 10)
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: The created token ID
    public func createBasicFungibleToken(
        treasuryAccountId: AccountId,
        treasuryKey: PrivateKey,
        initialSupply: UInt64 = TestConstants.testSmallInitialSupply,
        useAdminClient: Bool = false
    ) async throws -> TokenId {
        try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(treasuryAccountId)
                .initialSupply(initialSupply)
                .sign(treasuryKey),
            useAdminClient: useAdminClient
        )
    }

    /// Creates a fungible token with an explicit supply key.
    ///
    /// - Parameters:
    ///   - treasuryAccountId: Account to receive initial supply
    ///   - treasuryKey: Key to sign the transaction
    ///   - initialSupply: Initial token supply (default: 1,000,000)
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: Tuple of token ID and supply key
    public func createFungibleTokenWithSupplyKey(
        treasuryAccountId: AccountId,
        treasuryKey: PrivateKey,
        initialSupply: UInt64 = TestConstants.testFungibleInitialBalance,
        useAdminClient: Bool = false
    ) async throws -> (tokenId: TokenId, supplyKey: PrivateKey) {
        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(treasuryAccountId)
                .initialSupply(initialSupply)
                .supplyKey(.single(supplyKey.publicKey))
                .sign(treasuryKey),
            supplyKey: supplyKey,
            useAdminClient: useAdminClient
        )
        return (tokenId, supplyKey)
    }

    /// Creates an NFT token with an explicit supply key.
    ///
    /// - Parameters:
    ///   - treasuryAccountId: Account to be the treasury
    ///   - treasuryKey: Key to sign the transaction
    ///   - useAdminClient: Whether to use the admin client (default: false)
    /// - Returns: Tuple of token ID and supply key
    public func createNftWithSupplyKey(
        treasuryAccountId: AccountId,
        treasuryKey: PrivateKey,
        useAdminClient: Bool = false
    ) async throws -> (tokenId: TokenId, supplyKey: PrivateKey) {
        let supplyKey = PrivateKey.generateEd25519()
        let tokenId = try await createToken(
            TokenCreateTransaction()
                .name(TestConstants.tokenName)
                .symbol(TestConstants.tokenSymbol)
                .treasuryAccountId(treasuryAccountId)
                .supplyKey(.single(supplyKey.publicKey))
                .expirationTime(.now + .minutes(5))
                .tokenType(.nonFungibleUnique)
                .sign(treasuryKey),
            supplyKey: supplyKey,
            useAdminClient: useAdminClient
        )
        return (tokenId, supplyKey)
    }

    // MARK: - Token Association

    /// Associates a token with an account.
    ///
    /// - Parameters:
    ///   - tokenId: Token to associate
    ///   - accountId: Account to associate with
    ///   - key: Account key for signing
    ///   - useAdminClient: Whether to use the admin client (default: false)
    public func associateToken(
        _ tokenId: TokenId,
        with accountId: AccountId,
        key: PrivateKey,
        useAdminClient: Bool = false
    ) async throws {
        _ = try await TokenAssociateTransaction()
            .accountId(accountId)
            .tokenIds([tokenId])
            .sign(key)
            .execute(useAdminClient ? testEnv.adminClient : testEnv.client)
            .getReceipt(useAdminClient ? testEnv.adminClient : testEnv.client)
    }

    // MARK: - Token Assertions

    /// Asserts basic token info properties.
    ///
    /// - Parameters:
    ///   - info: Token info to validate
    ///   - tokenId: Expected token ID
    ///   - name: Expected name (default: TestConstants.tokenName)
    ///   - symbol: Expected symbol (default: TestConstants.tokenSymbol)
    public func assertTokenInfo(
        _ info: TokenInfo,
        tokenId: TokenId,
        name: String = TestConstants.tokenName,
        symbol: String = TestConstants.tokenSymbol,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(info.tokenId, tokenId, "Token ID mismatch", file: file, line: line)
        XCTAssertEqual(info.name, name, "Token name mismatch", file: file, line: line)
        XCTAssertEqual(info.symbol, symbol, "Token symbol mismatch", file: file, line: line)
    }

    // MARK: - Private Cleanup Logic

    /// Cleans up a token by burning/wiping supply and deleting it.
    private static func cleanupToken(
        tokenId: TokenId,
        adminKeys: [PrivateKey],
        supplyKey: PrivateKey?,
        wipeKey: PrivateKey?,
        client: Client
    ) async throws {
        // Burn/wipe all supply before deletion if supply key is provided
        if let supplyKey = supplyKey {
            let info = try await TokenInfoQuery(tokenId: tokenId).execute(client)
            if info.totalSupply > 0 {
                if info.tokenType == .nonFungibleUnique {
                    try await cleanupNftSupply(
                        tokenId: tokenId,
                        info: info,
                        supplyKey: supplyKey,
                        wipeKey: wipeKey,
                        client: client
                    )
                } else {
                    // For fungible tokens, burn by amount
                    _ = try await TokenBurnTransaction()
                        .tokenId(tokenId)
                        .amount(info.totalSupply)
                        .sign(supplyKey)
                        .execute(client)
                        .getReceipt(client)
                }
            }
        }

        // Delete the token
        let transaction = TokenDeleteTransaction(tokenId: tokenId)
        for key in adminKeys {
            transaction.sign(key)
        }
        _ = try await transaction.execute(client).getReceipt(client)
    }

    /// Cleans up NFT supply by wiping non-treasury NFTs and burning treasury NFTs.
    private static func cleanupNftSupply(
        tokenId: TokenId,
        info: TokenInfo,
        supplyKey: PrivateKey,
        wipeKey: PrivateKey?,
        client: Client
    ) async throws {
        var treasurySerials: [UInt64] = []
        var nonTreasurySerials: [(serial: UInt64, owner: AccountId)] = []

        // Search for existing NFTs
        var foundCount: UInt64 = 0
        var serial: UInt64 = 1
        let targetCount = info.totalSupply

        while foundCount < targetCount && serial <= targetCount * 10 + 100 {
            let nftId = tokenId.nft(serial)
            do {
                let nftInfo = try await TokenNftInfoQuery().nftId(nftId).execute(client)
                foundCount += 1
                if nftInfo.accountId == info.treasuryAccountId {
                    treasurySerials.append(serial)
                } else {
                    nonTreasurySerials.append((serial: serial, owner: nftInfo.accountId))
                }
            } catch {
                // NFT doesn't exist at this serial, continue searching
            }
            serial += 1
        }

        // Wipe NFTs from non-treasury accounts
        if let wipeKey = wipeKey, !nonTreasurySerials.isEmpty {
            var serialsByOwner: [AccountId: [UInt64]] = [:]
            for item in nonTreasurySerials {
                serialsByOwner[item.owner, default: []].append(item.serial)
            }

            for (owner, serials) in serialsByOwner {
                _ = try? await TokenWipeTransaction()
                    .tokenId(tokenId)
                    .accountId(owner)
                    .serials(serials)
                    .sign(wipeKey)
                    .execute(client)
                    .getReceipt(client)
            }
        }

        // Burn treasury NFTs
        if !treasurySerials.isEmpty {
            _ = try await TokenBurnTransaction()
                .tokenId(tokenId)
                .setSerials(treasurySerials)
                .sign(supplyKey)
                .execute(client)
                .getReceipt(client)
        }
    }
}
