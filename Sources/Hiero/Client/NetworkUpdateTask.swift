// SPDX-License-Identifier: Apache-2.0

import Atomics
import Foundation
import NIOCore

// MARK: - Network Update Task

/// Actor that periodically fetches and applies network address book updates.
///
/// This task runs in the background to keep the consensus network up-to-date with
/// the latest node addresses from the address book stored on the network itself.
/// It queries the mirror network for address book changes and atomically updates
/// the consensus network configuration.
///
/// ## Update Strategy
/// - Initial update after 10 seconds
/// - Subsequent updates at configured interval (default: 24 hours)
/// - Atomic updates preserve existing connections when addresses haven't changed
/// - Structured logging for debugging and monitoring
///
/// ## Related Types
/// - `ConsensusNetwork` - The network being updated
/// - `MirrorNetwork` - Source of address book data
/// - `NodeAddressBookQuery` - Fetches address book from network
internal actor NetworkUpdateTask {
    // MARK: - Constants

    /// Delay before the first network update after initialization
    private static let networkFirstUpdateDelay: Duration = .seconds(10)

    /// Nanoseconds per second for time calculations
    private static let nanosecondsPerSecond: UInt64 = 1_000_000_000

    // MARK: - Properties

    /// Event loop for network operations
    private let eventLoop: NIOCore.EventLoopGroup

    /// Atomic reference to the consensus network being updated
    private let consensusNetwork: ManagedAtomic<ConsensusNetwork>

    /// Atomic reference to the mirror network for address book queries
    private let mirrorNetwork: ManagedAtomic<MirrorNetwork>

    /// Whether to use only plaintext endpoints
    private let plaintext: Bool

    /// The background task performing periodic updates
    private var updateTask: Task<(), Error>?

    // MARK: - Initialization

    /// Creates a new network update task.
    ///
    /// - Parameters:
    ///   - eventLoop: Event loop for network operations
    ///   - consensusNetwork: Atomic reference to the consensus network
    ///   - mirrorNetwork: Atomic reference to the mirror network
    ///   - updatePeriod: Update interval in nanoseconds, or nil to disable updates
    ///   - shard: Shard number for address book file ID
    ///   - realm: Realm number for address book file ID
    internal init(
        eventLoop: NIOCore.EventLoopGroup,
        consensusNetwork: ManagedAtomic<ConsensusNetwork>,
        mirrorNetwork: ManagedAtomic<MirrorNetwork>,
        updatePeriod: UInt64?,
        shard: UInt64,
        realm: UInt64,
        plaintext: Bool = false
    ) {
        self.consensusNetwork = consensusNetwork
        self.mirrorNetwork = mirrorNetwork
        self.eventLoop = eventLoop
        self.plaintext = plaintext

        if let updatePeriod {
            updateTask = Self.makeTask(
                config: UpdateConfig(
                    eventLoop: eventLoop,
                    consensusNetwork: consensusNetwork,
                    mirrorNetwork: mirrorNetwork,
                    startDelay: Self.networkFirstUpdateDelay,
                    updatePeriod: updatePeriod,
                    shard: shard,
                    realm: realm,
                    plaintext: plaintext
                )
            )
        }
    }

    // MARK: - Public Methods

    /// Updates the network update period, canceling the existing task and starting a new one if needed.
    ///
    /// - Parameters:
    ///   - duration: New update interval in nanoseconds, or nil to disable updates
    ///   - shard: Shard number for address book file ID
    ///   - realm: Realm number for address book file ID
    internal func setUpdatePeriod(_ duration: UInt64?, shard: UInt64, realm: UInt64) {
        self.updateTask?.cancel()

        if let updatePeriod = duration {
            self.updateTask = Self.makeTask(
                config: UpdateConfig(
                    eventLoop: eventLoop,
                    consensusNetwork: consensusNetwork,
                    mirrorNetwork: mirrorNetwork,
                    startDelay: nil,
                    updatePeriod: updatePeriod,
                    shard: shard,
                    realm: realm,
                    plaintext: plaintext
                )
            )
        }
    }

    // MARK: - Private Types

    /// Configuration parameters for creating a network update task.
    ///
    /// This struct groups all parameters needed to configure and run the periodic
    /// network update loop, avoiding the need for functions with many parameters.
    private struct UpdateConfig {
        /// Event loop for network operations
        internal let eventLoop: NIOCore.EventLoopGroup

        /// Atomic reference to the consensus network being updated
        internal let consensusNetwork: ManagedAtomic<ConsensusNetwork>

        /// Atomic reference to the mirror network for queries
        internal let mirrorNetwork: ManagedAtomic<MirrorNetwork>

        /// Optional delay before the first update (nil for immediate start)
        internal let startDelay: Duration?

        /// Interval between updates in nanoseconds
        internal let updatePeriod: UInt64

        /// Shard number for address book file ID
        internal let shard: UInt64

        /// Realm number for address book file ID
        internal let realm: UInt64

        /// Whether to use only plaintext endpoints
        internal let plaintext: Bool
    }

    // MARK: - Private Methods

    /// Creates the background task that performs periodic network updates.
    ///
    /// The task runs an infinite loop that fetches the network address book from the
    /// mirror network and atomically updates the consensus network. Errors are logged
    /// but don't terminate the loop.
    ///
    /// - Parameter config: Configuration containing all necessary parameters for updates
    /// - Returns: A Task that can be canceled to stop the update loop
    private static func makeTask(config: UpdateConfig) -> Task<(), Error> {
        Task {
            // Initial delay before first update
            if let startDelay = config.startDelay {
                let delayNanos = startDelay.seconds * Self.nanosecondsPerSecond
                try await Task.sleep(nanoseconds: delayNanos)
            }

            // Continuous update loop
            while true {
                let start = Timestamp.now

                do {
                    // Fetch address book from mirror network
                    let mirror = config.mirrorNetwork.load(ordering: .relaxed)
                    let addressBook = try await NodeAddressBookQuery(
                        FileId.getAddressBookFileIdFor(shard: config.shard, realm: config.realm)
                    ).executeChannel(mirror.channel)

                    // Filter to plaintext-only endpoints if this is a plaintext-only client
                    let filtered: NodeAddressBook
                    if config.plaintext {
                        filtered = NodeAddressBook(
                            nodeAddresses: addressBook.nodeAddresses.map { address in
                                let plaintextEndpoints = address.serviceEndpoints.filter { endpoint in
                                    endpoint.port == NodeConnection.consensusPlaintextPort
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
                    } else {
                        filtered = addressBook
                    }

                    _ = config.consensusNetwork.readCopyUpdate { network in
                        ConsensusNetwork.withAddressBook(network, eventLoop: config.eventLoop.next(), filtered)
                    }

                    // Log successful update with structured format
                    print("[Hiero.NetworkUpdate] Consensus network updated successfully")

                } catch let error as HError {
                    // Log error with structured format and context
                    print(
                        "[Hiero.NetworkUpdate ERROR] Consensus network update failed: kind=\(error.kind), description=\(error.description)"
                    )
                } catch {
                    // Log unexpected error with structured format
                    print(
                        "[Hiero.NetworkUpdate ERROR] Consensus network update failed with unexpected error: \(error.localizedDescription)"
                    )
                }

                // Wait for the remainder of the update period
                let elapsed = (Timestamp.now - start).seconds * Self.nanosecondsPerSecond
                if elapsed < config.updatePeriod {
                    try await Task.sleep(nanoseconds: config.updatePeriod - elapsed)
                }
            }
        }
    }

    // MARK: - Lifecycle

    deinit {
        updateTask?.cancel()
    }
}
