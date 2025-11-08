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
internal actor NetworkUpdateTask: Sendable {
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
        realm: UInt64
    ) {
        self.consensusNetwork = consensusNetwork
        self.mirrorNetwork = mirrorNetwork
        self.eventLoop = eventLoop

        if let updatePeriod {
            updateTask = Self.makeTask(
                eventLoop,
                consensusNetwork,
                mirrorNetwork,
                Self.networkFirstUpdateDelay,
                updatePeriod,
                shard,
                realm
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
            self.updateTask = Self.makeTask(eventLoop, consensusNetwork, mirrorNetwork, nil, updatePeriod, shard, realm)
        }
    }

    // MARK: - Private Methods

    /// Creates the background task that performs periodic network updates.
    private static func makeTask(
        _ eventLoop: NIOCore.EventLoopGroup,
        _ consensusNetwork: ManagedAtomic<ConsensusNetwork>,
        _ mirrorNetwork: ManagedAtomic<MirrorNetwork>,
        _ startDelay: Duration?,
        _ updatePeriod: UInt64,
        _ shard: UInt64,
        _ realm: UInt64
    ) -> Task<(), Error> {
        Task {
            // Initial delay before first update
            if let startDelay {
                let delayNanos = startDelay.seconds * Self.nanosecondsPerSecond
                try await Task.sleep(nanoseconds: delayNanos)
            }

            // Continuous update loop
            while true {
                let start = Timestamp.now

                do {
                    // Fetch address book from mirror network
                    let mirror = mirrorNetwork.load(ordering: .relaxed)
                    let addressBook = try await NodeAddressBookQuery(
                        FileId.getAddressBookFileIdFor(shard: shard, realm: realm)
                    ).executeChannel(mirror.channel)

                    // Apply updates to consensus network atomically
                    let newNetwork = consensusNetwork.readCopyUpdate {
                        ConsensusNetwork.withAddressBook($0, eventLoop: eventLoop.next(), addressBook)
                    }

                    // Log successful update with structured format
                    print(
                        "[Hiero.NetworkUpdate] Consensus network updated successfully with \(newNetwork.nodes.count) nodes"
                    )

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
                if elapsed < updatePeriod {
                    try await Task.sleep(nanoseconds: updatePeriod - elapsed)
                }
            }
        }
    }

    // MARK: - Lifecycle

    deinit {
        updateTask?.cancel()
    }
}
