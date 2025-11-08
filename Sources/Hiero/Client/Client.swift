// SPDX-License-Identifier: Apache-2.0

import Atomics
import Foundation
import GRPC
import NIOConcurrencyHelpers
import NIOCore

// MARK: - Client

/// Primary interface for interacting with the Hedera network.
///
/// The Client manages network connections, transaction submission, and query execution.
/// It handles automatic retry logic, node selection, health tracking, and load balancing
/// across consensus and mirror nodes.
///
/// Example usage:
/// ```swift
/// // Create a client for testnet
/// let client = try await Client.forTestnet()
///
/// // Set operator account for signing transactions
/// try client.setOperator(accountId, privateKey)
///
/// // Execute transactions and queries
/// let balance = try await AccountBalanceQuery()
///     .accountId(accountId)
///     .execute(client)
/// ```
public final class Client: Sendable {
    // MARK: - Properties

    /// Event loop group for managing asynchronous I/O operations
    internal let eventLoop: NIOCore.EventLoopGroup

    /// Thread-safe reference to the consensus network
    private let _consensusNetwork: ManagedAtomic<ConsensusNetwork>

    /// Thread-safe reference to the mirror network
    private let _mirrorNetwork: ManagedAtomic<MirrorNetwork>

    /// Operator account and key for signing transactions
    private let _operator: NIOLockedValueBox<Operator?>

    /// Whether to automatically validate checksums in IDs
    private let _autoValidateChecksums: ManagedAtomic<Bool>

    /// Background task for periodic network address book updates
    private let networkUpdateTask: NetworkUpdateTask

    /// Whether to regenerate transaction IDs on expiry
    private let _regenerateTransactionId: ManagedAtomic<Bool>

    /// Maximum transaction fee in tinybars (0 = no limit)
    private let _maxTransactionFee: ManagedAtomic<Int64>

    /// Network update period in nanoseconds
    private let _networkUpdatePeriod: NIOLockedValueBox<UInt64?>

    /// Exponential backoff configuration for retries
    private let _backoff: NIOLockedValueBox<Backoff>

    /// Shard number for this client's network (backing storage)
    private let _shard: UInt64

    /// Realm number for this client's network (backing storage)
    private let _realm: UInt64

    // MARK: - Initialization

    /// Primary designated initializer.
    ///
    /// - Parameters:
    ///   - consensus: Consensus network configuration
    ///   - mirror: Mirror network configuration
    ///   - ledgerId: Ledger ID for validation (optional)
    ///   - networkUpdatePeriod: Update interval in nanoseconds (default: 24 hours)
    ///   - eventLoop: Event loop group for I/O
    ///   - shard: Shard number (default: 0)
    ///   - realm: Realm number (default: 0)
    private init(
        consensus: ConsensusNetwork,
        mirror: MirrorNetwork,
        ledgerId: LedgerId?,
        networkUpdatePeriod: UInt64? = 86400 * 1_000_000_000,
        _ eventLoop: NIOCore.EventLoopGroup,
        shard: UInt64 = 0,
        realm: UInt64 = 0
    ) {
        self.eventLoop = eventLoop
        self._consensusNetwork = .init(consensus)
        self._mirrorNetwork = .init(mirror)
        self._operator = .init(nil)
        self._ledgerId = .init(ledgerId)
        self._autoValidateChecksums = .init(false)
        self._regenerateTransactionId = .init(true)
        self._maxTransactionFee = .init(0)
        self.networkUpdateTask = NetworkUpdateTask(
            eventLoop: eventLoop,
            consensusNetwork: _consensusNetwork,
            mirrorNetwork: _mirrorNetwork,
            updatePeriod: networkUpdatePeriod,
            shard: shard,
            realm: realm
        )
        self._networkUpdatePeriod = .init(networkUpdatePeriod)
        self._backoff = .init(Backoff())
        self._shard = shard
        self._realm = realm
    }

    // MARK: - Internal Accessors

    /// All consensus node account IDs.
    ///
    /// - Note: This operation is O(n) as it loads the current network snapshot
    private var consensusNodeIds: [AccountId] {
        _consensusNetwork.load(ordering: .relaxed).nodes
    }

    /// GRPC channel for mirror node queries
    internal var mirrorChannel: GRPCChannel { mirror.channel }

    /// Current operator account and key
    internal var `operator`: Operator? {
        return _operator.withLockedValue { $0 }
    }

    /// Maximum transaction fee, or nil if unlimited
    internal var maxTransactionFee: Hbar? {
        let value = _maxTransactionFee.load(ordering: .relaxed)

        guard value != 0 else {
            return nil
        }

        return .fromTinybars(value)
    }

    // MARK: - Public Accessors

    /// Returns the shard number for this client's network.
    public func getShard() -> UInt64 {
        return _shard
    }

    /// Returns the realm number for this client's network.
    public func getRealm() -> UInt64 {
        return _realm
    }

    // MARK: - Retry Configuration

    /// Maximum time spent on a single request including all retries.
    ///
    /// Setting this to nil removes the timeout limit.
    public var requestTimeout: TimeInterval? {
        get { backoff.requestTimeout }
        set(value) { _backoff.withLockedValue { $0.requestTimeout = value } }
    }

    /// Maximum number of attempts for a request before giving up.
    ///
    /// Default is typically 10 attempts.
    public var maxAttempts: Int {
        get { backoff.maxAttempts }
        set(value) { _backoff.withLockedValue { $0.maxAttempts = value } }
    }

    /// Initial backoff delay for the first retry.
    ///
    /// Subsequent retries use exponential backoff from this initial value.
    public var minBackoff: TimeInterval {
        get { backoff.initialBackoff }
        set(value) { _backoff.withLockedValue { $0.initialBackoff = value } }
    }

    /// Maximum backoff delay between retry attempts.
    ///
    /// Exponential backoff will not exceed this value.
    public var maxBackoff: TimeInterval {
        get { backoff.maxBackoff }
        set(value) { _backoff.withLockedValue { $0.maxBackoff = value } }
    }

    /// Current backoff configuration
    internal var backoff: Backoff {
        self._backoff.withLockedValue { $0 }
    }

    // MARK: - Factory Methods

    /// Creates a client with custom network addresses.
    ///
    /// - Parameters:
    ///   - addresses: Dictionary mapping address strings to account IDs
    ///   - shard: Shard number (default: 0)
    ///   - realm: Realm number (default: 0)
    /// - Returns: A new client configured for the specified network
    /// - Throws: HError if addresses cannot be parsed
    public static func forNetwork(_ addresses: [String: AccountId], shard: UInt64 = 0, realm: UInt64 = 0) throws -> Self
    {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        return Self(
            consensus: try .init(addresses: addresses, eventLoop: eventLoop.next()),
            mirror: .init(targets: [], eventLoop: eventLoop),
            ledgerId: nil,
            eventLoop,
            shard: shard,
            realm: realm
        )
    }

    /// Creates a client by bootstrapping from mirror nodes.
    ///
    /// Fetches the network address book from the mirror network and configures
    /// consensus nodes accordingly. This allows for dynamic network configuration.
    ///
    /// - Parameters:
    ///   - mirrorNetworks: Array of mirror node addresses
    ///   - shard: Shard number (default: 0)
    ///   - realm: Realm number (default: 0)
    /// - Returns: A new client configured with the fetched address book
    /// - Throws: HError if address book fetch fails
    public static func forMirrorNetwork(
        _ mirrorNetworks: [String],
        shard: UInt64 = 0,
        realm: UInt64 = 0
    ) async throws -> Self {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)

        let transportSecurity: GRPCChannelPool.Configuration.TransportSecurity =
            mirrorNetworks.allSatisfy { $0.contains("localhost") || $0.contains("127.0.0.1") }
            ? .plaintext
            : .tls(.makeClientDefault(compatibleWith: eventLoop))

        let client = Self(
            consensus: try .init(addresses: [:], eventLoop: eventLoop.next()),
            mirror: MirrorNetwork(
                targets: mirrorNetworks,
                eventLoop: eventLoop,
                transportSecurity: transportSecurity
            ),
            ledgerId: nil,
            eventLoop,
            shard: shard,
            realm: realm
        )

        let addressBook = try await NodeAddressBookQuery()
            .setFileId(FileId.getAddressBookFileIdFor(shard: shard, realm: realm))
            .execute(client)

        // Only take the plaintext nodes
        let filtered = NodeAddressBook(
            nodeAddresses: addressBook.nodeAddresses.map { address in
                let plaintextEndpoints = address.serviceEndpoints.filter {
                    $0.port == NodeConnection.consensusPlaintextPort
                }

                return NodeAddress(
                    nodeId: address.nodeId,
                    rsaPublicKey: address.rsaPublicKey,
                    nodeAccountId: address.nodeAccountId,
                    tlsCertificateHash: address.tlsCertificateHash,
                    serviceEndpoints: plaintextEndpoints,
                    description: address.description)
            }
        )

        client.setNetworkFromAddressBook(filtered)

        return client
    }

    /// Creates a client pre-configured for Hedera mainnet.
    ///
    /// Connects to the public Hedera mainnet with default node addresses.
    ///
    /// - Returns: A new client configured for mainnet
    public static func forMainnet() -> Self {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        return Self(
            consensus: .mainnet(eventLoop),
            mirror: .mainnet(eventLoop),
            ledgerId: .mainnet,
            eventLoop
        )
    }

    /// Creates a client pre-configured for Hedera testnet.
    ///
    /// Connects to the public Hedera testnet with default node addresses.
    ///
    /// - Returns: A new client configured for testnet
    public static func forTestnet() -> Self {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        return Self(
            consensus: .testnet(eventLoop),
            mirror: .testnet(eventLoop),
            ledgerId: .testnet,
            eventLoop
        )
    }

    /// Creates a client pre-configured for Hedera previewnet.
    ///
    /// Connects to the public Hedera previewnet with default node addresses.
    ///
    /// - Returns: A new client configured for previewnet
    public static func forPreviewnet() -> Self {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        return Self(
            consensus: .previewnet(eventLoop),
            mirror: .previewnet(eventLoop),
            ledgerId: .previewnet,
            eventLoop
        )
    }

    /// Creates a client from a JSON configuration string.
    ///
    /// The configuration should include network addresses, optional operator account,
    /// and other client settings. See `ClientConfig` for the configuration format.
    ///
    /// - Parameter config: JSON configuration string
    /// - Returns: A new client configured from the JSON
    /// - Throws: HError if configuration cannot be parsed
    public static func fromConfig(_ config: String) throws -> Self {
        let configData: ClientConfig
        do {
            configData = try JSONDecoder().decode(ClientConfig.self, from: config.data(using: .utf8)!)
        } catch let error as DecodingError {
            throw HError.basicParse(String(describing: error))
        }

        // Use NetworkFactory to create networks from specifications
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        
        let consensus = try NetworkFactory.makeConsensusNetwork(
            spec: configData.network,
            eventLoop: eventLoop,
            shard: configData.shard,
            realm: configData.realm
        )
        
        let mirror = try NetworkFactory.makeMirrorNetwork(
            spec: configData.mirrorNetwork,
            eventLoop: eventLoop
        )
        
        // Determine ledger ID from network name if available
        let ledgerId: LedgerId?
        if case .predefined(let name) = configData.network {
            ledgerId = NetworkFactory.ledgerIdForNetworkName(name)
        } else {
            ledgerId = nil
        }
        
        let client = Self(
            consensus: consensus,
            mirror: mirror,
            ledgerId: ledgerId,
            eventLoop,
            shard: configData.shard,
            realm: configData.realm
        )

        // Set operator if provided
        if let `operator` = configData.operator {
            client._operator.withLockedValue { $0 = `operator` }
        }

        return client
    }

    /// Creates a client by network name (mainnet, testnet, previewnet, or localhost).
    ///
    /// - Parameter name: Network name ("mainnet", "testnet", "previewnet", or "localhost")
    /// - Returns: A new client configured for the named network
    /// - Throws: HError if network name is unknown
    public static func forName(_ name: String) throws -> Self {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        
        // Use NetworkFactory for consistent network creation
        let consensus = try NetworkFactory.makeConsensusNetworkByName(name, eventLoop: eventLoop)
        let mirror = try NetworkFactory.makeMirrorNetworkByName(name, eventLoop: eventLoop)
        let ledgerId = NetworkFactory.ledgerIdForNetworkName(name)
        
        return Self(
            consensus: consensus,
            mirror: mirror,
            ledgerId: ledgerId,
            eventLoop
        )
    }

    // MARK: - Client Configuration

    /// Sets the operator account for signing and paying for transactions.
    ///
    /// The operator account is used by default for all transactions unless explicitly overridden.
    ///
    /// - Parameters:
    ///   - accountId: Account ID to use as operator
    ///   - privateKey: Private key for signing transactions
    /// - Returns: Self for method chaining
    @discardableResult
    public func setOperator(_ accountId: AccountId, _ privateKey: PrivateKey) -> Self {
        _operator.withLockedValue { $0 = .init(accountId: accountId, signer: .privateKey(privateKey)) }

        return self
    }

    // MARK: - Network Health

    /// Pings a specific node to check if it's reachable.
    ///
    /// - Parameter nodeAccountId: Account ID of the node to ping
    /// - Throws: HError if the node is unreachable or returns an error
    public func ping(_ nodeAccountId: AccountId) async throws {
        try await PingQuery(nodeAccountId: nodeAccountId).execute(self)
    }

    /// Pings a specific node with a custom timeout.
    ///
    /// - Parameters:
    ///   - nodeAccountId: Account ID of the node to ping
    ///   - timeout: Timeout interval for the ping
    /// - Throws: HError if the node is unreachable or returns an error
    public func ping(_ nodeAccountId: AccountId, _ timeout: TimeInterval) async throws {
        try await PingQuery(nodeAccountId: nodeAccountId).execute(self, timeout: timeout)
    }

    /// Pings all nodes in the network concurrently.
    ///
    /// - Throws: HError if any node ping fails
    public func pingAll() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for node in self.consensusNodeIds {
                group.addTask {
                    try await self.ping(node)
                }

                try await group.waitForAll()
            }
        }
    }

    /// Pings all nodes in the network concurrently with a custom timeout.
    ///
    /// - Parameter timeout: Timeout interval for each ping
    /// - Throws: HError if any node ping fails
    public func pingAll(_ timeout: TimeInterval) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for node in self.consensusNodeIds {
                group.addTask {
                    try await self.ping(node, timeout)
                }

                try await group.waitForAll()
            }
        }
    }

    // MARK: - Ledger ID Configuration

    /// Internal storage for ledger ID
    private let _ledgerId: NIOLockedValueBox<LedgerId?>

    /// Sets the ledger ID for transaction validation.
    ///
    /// - Parameter ledgerId: Ledger ID to validate against, or nil to disable validation
    /// - Returns: Self for method chaining
    @discardableResult
    public func setLedgerId(_ ledgerId: LedgerId?) -> Self {
        self.ledgerId = ledgerId

        return self
    }

    /// Ledger ID for validating transactions.
    ///
    /// When set, transactions will be validated to ensure they're for the correct network.
    public var ledgerId: LedgerId? {
        get {
            _ledgerId.withLockedValue { $0 }
        }

        set(value) {
            _ledgerId.withLockedValue { $0 = value }
        }
    }

    // MARK: - Checksum Validation

    /// Internal storage for auto-validate checksums flag
    fileprivate var autoValidateChecksums: Bool {
        get { self._autoValidateChecksums.load(ordering: .relaxed) }
        set(value) { self._autoValidateChecksums.store(value, ordering: .relaxed) }
    }

    /// Enables or disables automatic checksum validation for entity IDs.
    ///
    /// When enabled, entity IDs with checksums will be validated before use.
    ///
    /// - Parameter autoValidateChecksums: Whether to enable automatic validation
    /// - Returns: Self for method chaining
    @discardableResult
    public func setAutoValidateChecksums(_ autoValidateChecksums: Bool) -> Self {
        self.autoValidateChecksums = autoValidateChecksums

        return self
    }

    /// Returns whether automatic checksum validation is enabled.
    public func isAutoValidateChecksumsEnabled() -> Bool {
        autoValidateChecksums
    }

    // MARK: - Transaction ID Regeneration

    /// Whether transaction IDs should be automatically regenerated on expiry.
    ///
    /// When true (default), expired transactions will automatically receive a new
    /// transaction ID and be retried. Some operations like explicitly setting the
    /// transaction ID will disable this behavior.
    public var defaultRegenerateTransactionId: Bool {
        get { self._regenerateTransactionId.load(ordering: .relaxed) }
        set(value) { self._regenerateTransactionId.store(value, ordering: .relaxed) }
    }

    /// Sets whether transaction IDs should be regenerated on expiry.
    ///
    /// - Parameter defaultRegenerateTransactionId: Whether to enable regeneration
    /// - Returns: Self for method chaining
    @discardableResult
    public func setDefaultRegenerateTransactionId(_ defaultRegenerateTransactionId: Bool) -> Self {
        self.defaultRegenerateTransactionId = defaultRegenerateTransactionId

        return self
    }

    // MARK: - Internal Helpers

    /// Generates a transaction ID from the operator account.
    internal func generateTransactionId() -> TransactionId? {
        (self.operator?.accountId).map { .generateFrom($0) }
    }

    /// Current consensus network snapshot (internal accessor)
    internal var consensus: ConsensusNetwork {
        _consensusNetwork.load(ordering: .relaxed)
    }

    /// Current mirror network, with atomic read/write access (internal accessor)
    internal var mirror: MirrorNetwork {
        get { _mirrorNetwork.load(ordering: .relaxed) }
        set(value) { _mirrorNetwork.store(value, ordering: .relaxed) }
    }

    // MARK: - Network Management

    /// Returns all consensus network addresses.
    public var network: [String: AccountId] {
        consensus.addresses
    }

    /// Updates the consensus network addresses.
    ///
    /// This atomically replaces the network configuration, reusing existing
    /// connections where node addresses haven't changed.
    ///
    /// - Parameter network: Dictionary mapping addresses to account IDs
    /// - Returns: Self for method chaining
    /// - Throws: HError if addresses cannot be parsed
    @discardableResult
    public func setNetwork(_ network: [String: AccountId]) throws -> Self {
        _ = try self._consensusNetwork.readCopyUpdate { old in
            try ConsensusNetwork.withAddresses(old, addresses: network, eventLoop: self.eventLoop.next())
        }

        return self
    }

    /// Mirror network addresses as strings.
    public var mirrorNetwork: [String] {
        get {
            let mirror = _mirrorNetwork.load(ordering: .relaxed)
            return Array(mirror.addresses.map { "\($0.host):\($0.port)" })
        }
        set(value) {
            _mirrorNetwork.store(.init(targets: value, eventLoop: eventLoop), ordering: .relaxed)
        }
    }

    /// Sets the mirror network addresses.
    ///
    /// Useful when using a custom network that needs mirror node configuration.
    ///
    /// - Parameter addresses: Array of mirror node addresses
    /// - Returns: Self for method chaining
    @discardableResult
    public func setMirrorNetwork(_ addresses: [String]) -> Self {
        mirror = .init(targets: addresses, eventLoop: eventLoop)

        return self
    }

    /// Replaces all consensus nodes with addresses from an address book.
    ///
    /// This atomically updates the network while preserving connections to
    /// unchanged nodes.
    ///
    /// - Parameter addressBook: Node address book from the network
    /// - Returns: Self for method chaining
    @discardableResult
    public func setNetworkFromAddressBook(_ addressBook: NodeAddressBook) -> Self {
        _ = try? self._consensusNetwork.readCopyUpdate { old in
            try ConsensusNetwork.withAddresses(
                old, addresses: ConsensusNetwork.addressMap(from: addressBook.nodeAddresses), eventLoop: self.eventLoop.next())
        }

        return self
    }

    /// Current network update period in nanoseconds, or nil if updates are disabled.
    public var networkUpdatePeriod: UInt64? {
        _networkUpdatePeriod.withLockedValue { $0 }
    }

    /// Sets the network update period for automatic address book refreshes.
    ///
    /// - Parameter nanoseconds: Update interval in nanoseconds, or nil to disable updates
    public func setNetworkUpdatePeriod(nanoseconds: UInt64?) async {
        await self.networkUpdateTask.setUpdatePeriod(nanoseconds, shard: _shard, realm: _realm)
        self._networkUpdatePeriod.withLockedValue { $0 = nanoseconds }
    }

}
