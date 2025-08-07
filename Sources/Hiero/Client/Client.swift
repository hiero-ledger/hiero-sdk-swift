// SPDX-License-Identifier: Apache-2.0

import Atomics
import Foundation
import GRPC
import NIOConcurrencyHelpers
import NIOCore

/// Managed client for use on the Hedera network.
public final class Client: Sendable {
    internal let eventLoop: NIOCore.EventLoopGroup

    private let networkInner: ManagedNetwork
    private let operatorInner: NIOLockedValueBox<Operator?>
    private let autoValidateChecksumsInner: ManagedAtomic<Bool>
    private let networkUpdateTask: NetworkUpdateTask
    private let regenerateTransactionIdInner: ManagedAtomic<Bool>
    private let maxTransactionFeeInner: ManagedAtomic<Int64>
    private let networkUpdatePeriodInner: NIOLockedValueBox<UInt64?>
    private let backoffInner: NIOLockedValueBox<Backoff>
    private let shard: UInt64
    private let realm: UInt64

    private init(
        network: ManagedNetwork,
        ledgerId: LedgerId?,
        networkUpdatePeriod: UInt64? = 86400 * 1_000_000_000,
        _ eventLoop: NIOCore.EventLoopGroup,
        shard: UInt64 = 0,
        realm: UInt64 = 0
    ) {
        self.eventLoop = eventLoop
        self.networkInner = network
        self.operatorInner = .init(nil)
        self.ledgerIdInner = .init(ledgerId)
        self.autoValidateChecksumsInner = .init(false)
        self.regenerateTransactionIdInner = .init(true)
        self.maxTransactionFeeInner = .init(0)
        self.networkUpdateTask = NetworkUpdateTask(
            eventLoop: eventLoop,
            managedNetwork: network,
            updatePeriod: networkUpdatePeriod,
            shard: shard,
            realm: realm
        )
        self.networkUpdatePeriodInner = .init(networkUpdatePeriod)
        self.backoffInner = .init(Backoff())
        self.shard = shard
        self.realm = realm
    }

    /// Note: this operation is O(n)
    private var nodes: [AccountId] {
        networkInner.primary.load(ordering: .relaxed).nodes
    }

    internal var mirrorChannel: GRPCChannel { mirrorNet.channel }

    internal var `operator`: Operator? {
        return operatorInner.withLockedValue { $0 }
    }

    internal var maxTransactionFee: Hbar? {
        let value = maxTransactionFeeInner.load(ordering: .relaxed)

        guard value != 0 else {
            return nil
        }

        return .fromTinybars(value)
    }

    public func getShard() -> UInt64 {
        return shard
    }

    public func getRealm() -> UInt64 {
        return realm
    }

    /// The maximum amount of time that will be spent on a request.
    public var requestTimeout: TimeInterval? {
        get { backoff.requestTimeout }
        set(value) { backoffInner.withLockedValue { $0.requestTimeout = value } }
    }

    /// The maximum number of attempts for a request.
    public var maxAttempts: Int {
        get { backoff.maxAttempts }
        set(value) { backoffInner.withLockedValue { $0.maxAttempts = value } }
    }

    /// The initial backoff for a request being executed.
    public var minBackoff: TimeInterval {
        get { backoff.initialBackoff }
        set(value) { backoffInner.withLockedValue { $0.initialBackoff = value } }
    }

    /// The maximum amount of time a request will wait between attempts.
    public var maxBackoff: TimeInterval {
        get { backoff.maxBackoff }
        set(value) { backoffInner.withLockedValue { $0.maxBackoff = value } }
    }

    internal var backoff: Backoff {
        self.backoffInner.withLockedValue { $0 }
    }

    public static func forNetwork(_ addresses: [String: AccountId], shard: UInt64 = 0, realm: UInt64 = 0) throws -> Self
    {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        return Self(
            network: .init(
                primary: try .init(addresses: addresses, eventLoop: eventLoop.next()),
                mirror: .init(targets: [], eventLoop: eventLoop)
            ),
            ledgerId: nil,
            eventLoop,
            shard: shard,
            realm: realm
        )
    }

    /// Set up the client from selected mirror network.
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
            network: .init(
                primary: try .init(addresses: [:], eventLoop: eventLoop.next()),
                mirror: MirrorNetwork(
                    targets: mirrorNetworks,
                    eventLoop: eventLoop,
                    transportSecurity: transportSecurity
                )
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
                let plaintextEndpoints = address.serviceEndpoints.filter { $0.port == NodeConnection.consensusPlaintextPort }

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

    /// Construct a Hedera client pre-configured for mainnet access.
    public static func forMainnet() -> Self {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        return Self(
            network: .mainnet(eventLoop),
            ledgerId: .mainnet,
            eventLoop
        )
    }

    /// Construct a Hedera client pre-configured for testnet access.
    public static func forTestnet() -> Self {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        return Self(
            network: .testnet(eventLoop),
            ledgerId: .testnet,
            eventLoop
        )
    }

    /// Construct a Hedera client pre-configured for previewnet access.
    public static func forPreviewnet() -> Self {
        let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        return Self(
            network: .previewnet(eventLoop),
            ledgerId: .previewnet,
            eventLoop
        )
    }

    public static func fromConfig(_ config: String) throws -> Self {
        let configData: Config
        do {
            configData = try JSONDecoder().decode(Config.self, from: config.data(using: .utf8)!)
        } catch let error as DecodingError {
            throw HError.basicParse(String(describing: error))
        }

        let `operator` = configData.operator
        let network = configData.network
        let mirrorNetwork = configData.mirrorNetwork
        let shard = configData.shard
        let realm = configData.realm

        // fixme: check to ensure net and mirror net are the same when they're a network name (no other SDK actually checks this though)
        let client: Self
        switch network {
        case .left(let network):
            client = try Self.forNetwork(network, shard: shard, realm: realm)
        case .right(.mainnet): client = .forMainnet()
        case .right(.testnet): client = .forTestnet()
        case .right(.previewnet): client = .forPreviewnet()
        }

        if let `operator` = `operator` {
            client.operatorInner.withLockedValue { $0 = `operator` }
        }

        switch mirrorNetwork {
        case nil: break
        case .left(let mirrorNetwork):
            client.mirrorNetwork = mirrorNetwork
        case .right(.mainnet): client.mirrorNet = .mainnet(client.eventLoop)
        case .right(.testnet): client.mirrorNet = .testnet(client.eventLoop)
        case .right(.previewnet): client.mirrorNet = .previewnet(client.eventLoop)
        }

        return client
    }

    // wish I could write `init(for name: String)`
    public static func forName(_ name: String) throws -> Self {
        switch name {
        case "mainnet":
            return .forMainnet()

        case "testnet":
            return .forTestnet()

        case "previewnet":
            return .forPreviewnet()

        case "localhost":
            let network: [String: AccountId] = ["127.0.0.1:50211": AccountId(num: 3)]
            let eventLoop = PlatformSupport.makeEventLoopGroup(loopCount: 1)

            let client = try Client.forNetwork(network)
            client.mirrorNet = MirrorNetwork.localhost(eventLoop)

            return Self(
                network: client.networkInner,
                ledgerId: nil,
                eventLoop
            )

        default:
            throw HError.basicParse("Unknown network name \(name)")
        }
    }

    /// Sets the account that will, by default, be paying for transactions and queries built with
    /// this client.
    @discardableResult
    public func setOperator(_ accountId: AccountId, _ privateKey: PrivateKey) -> Self {
        operatorInner.withLockedValue { $0 = .init(accountId: accountId, signer: .privateKey(privateKey)) }

        return self
    }

    public func ping(_ nodeAccountId: AccountId) async throws {
        try await PingQuery(nodeAccountId: nodeAccountId).execute(self)
    }

    public func ping(_ nodeAccountId: AccountId, _ timeout: TimeInterval) async throws {
        try await PingQuery(nodeAccountId: nodeAccountId).execute(self, timeout: timeout)
    }

    public func pingAll() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for node in self.nodes {
                group.addTask {
                    try await self.ping(node)
                }

                try await group.waitForAll()
            }
        }
    }

    public func pingAll(_ timeout: TimeInterval) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for node in self.nodes {
                group.addTask {
                    try await self.ping(node, timeout)
                }

                try await group.waitForAll()
            }
        }
    }

    private let ledgerIdInner: NIOLockedValueBox<LedgerId?>

    @discardableResult
    public func setLedgerId(_ ledgerId: LedgerId?) -> Self {
        self.ledgerId = ledgerId

        return self
    }

    // note: matches JS
    public var ledgerId: LedgerId? {
        get {
            ledgerIdInner.withLockedValue { $0 }
        }

        set(value) {
            ledgerIdInner.withLockedValue { $0 = value }
        }
    }

    fileprivate var autoValidateChecksums: Bool {
        get { self.autoValidateChecksumsInner.load(ordering: .relaxed) }
        set(value) { self.autoValidateChecksumsInner.store(value, ordering: .relaxed) }
    }

    @discardableResult
    public func setAutoValidateChecksums(_ autoValidateChecksums: Bool) -> Self {
        self.autoValidateChecksums = autoValidateChecksums

        return self
    }

    public func isAutoValidateChecksumsEnabled() -> Bool {
        autoValidateChecksums
    }

    /// Whether or not the transaction ID should be refreshed if a ``Status/transactionExpired`` occurs.
    ///
    /// By default, this is true.
    ///
    /// >Note: Some operations forcibly disable transaction ID regeneration, such as setting the transaction ID explicitly.
    public var defaultRegenerateTransactionId: Bool {
        get { self.regenerateTransactionIdInner.load(ordering: .relaxed) }
        set(value) { self.regenerateTransactionIdInner.store(value, ordering: .relaxed) }
    }

    /// Sets whether or not the transaction ID should be refreshed if a ``Status/transactionExpired`` occurs.
    ///
    /// Various operations such as setting the transaction ID exlicitly can forcibly disable transaction ID regeneration.
    @discardableResult
    public func setDefaultRegenerateTransactionId(_ defaultRegenerateTransactionId: Bool) -> Self {
        self.defaultRegenerateTransactionId = defaultRegenerateTransactionId

        return self
    }

    internal func generateTransactionId() -> TransactionId? {
        (self.operator?.accountId).map { .generateFrom($0) }
    }

    internal var net: Network {
        networkInner.primary.load(ordering: .relaxed)
    }

    internal var mirrorNet: MirrorNetwork {
        get { networkInner.mirror.load(ordering: .relaxed) }
        set(value) { networkInner.mirror.store(value, ordering: .relaxed) }
    }

    public var network: [String: AccountId] {
        net.addresses
    }

    @discardableResult
    public func setNetwork(_ network: [String: AccountId]) throws -> Self {
        _ = try self.networkInner.primary.readCopyUpdate { old in
            try Network.withAddresses(old, network, eventLoop: self.eventLoop.next())
        }

        return self
    }

    public var mirrorNetwork: [String] {
        get { Array(mirrorNet.addresses.map { "\($0.host):\($0.port)" }) }
        set(value) {
            self.mirrorNet = .init(targets: value, eventLoop: eventLoop)
        }
    }

    /// Sets the addresses to use for the mirror network.
    ///
    /// This is mostly useful if you used `Self.fromNetwork` and need to set a mirror network.
    @discardableResult
    public func setMirrorNetwork(_ addresses: [String]) -> Self {
        mirrorNetwork = addresses

        return self
    }

    /// Replace all nodes in this Client with a new set of nodes from the given address book.
    /// This preserves and makes appropriate updates to the existing Client.
    @discardableResult
    public func setNetworkFromAddressBook(_ addressBook: NodeAddressBook) -> Self {
        _ = try? self.networkInner.primary.readCopyUpdate { old in
            try Network.withAddresses(
                old, Network.addressBookToNetwork(addressBook.nodeAddresses), eventLoop: self.eventLoop.next())
        }

        return self
    }

    public var networkUpdatePeriod: UInt64? {
        networkUpdatePeriodInner.withLockedValue { $0 }
    }

    public func setNetworkUpdatePeriod(nanoseconds: UInt64?) async {
        await self.networkUpdateTask.setUpdatePeriod(nanoseconds, shard, realm)
        self.networkUpdatePeriodInner.withLockedValue { $0 = nanoseconds }
    }

}

extension Client {
    internal struct Backoff {
        internal init(
            maxBackoff: TimeInterval = LegacyExponentialBackoff.defaultMaxInterval,
            initialBackoff: TimeInterval = LegacyExponentialBackoff.defaultInitialInterval,
            maxAttempts: Int = 10,
            requestTimeout: TimeInterval? = nil,
            grpcTimeout: TimeInterval? = nil
        ) {
            self.maxBackoff = maxBackoff
            self.initialBackoff = initialBackoff
            self.maxAttempts = maxAttempts
            self.requestTimeout = requestTimeout
            self.grpcTimeout = grpcTimeout
        }

        internal var maxBackoff: TimeInterval
        // min backoff.
        internal var initialBackoff: TimeInterval
        internal var maxAttempts: Int
        internal var requestTimeout: TimeInterval?
        internal var grpcTimeout: TimeInterval?
    }
}
