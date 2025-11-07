import Atomics
import Foundation
import NIOConcurrencyHelpers
import NIOCore

internal final class ManagedNetwork: Sendable {
    internal init(primary: Network, mirror: MirrorNetwork) {
        self.primary = .init(primary)
        self.mirror = .init(mirror)
    }

    internal static let networkFirstUpdateDelay: Duration = .seconds(10)

    internal let primary: ManagedAtomic<Network>
    internal let mirror: ManagedAtomic<MirrorNetwork>

    internal static func mainnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(primary: .mainnet(eventLoop), mirror: .mainnet(eventLoop))
    }

    internal static func testnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(primary: .testnet(eventLoop), mirror: .testnet(eventLoop))
    }

    internal static func previewnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(primary: .previewnet(eventLoop), mirror: .previewnet(eventLoop))
    }
}

internal actor NetworkUpdateTask: Sendable {
    internal init(
        eventLoop: NIOCore.EventLoopGroup, managedNetwork: ManagedNetwork, updatePeriod: UInt64?, shard: UInt64,
        realm: UInt64, plaintextOnly: Bool = false
    ) {
        self.managedNetwork = managedNetwork
        self.eventLoop = eventLoop
        self.plaintextOnly = plaintextOnly

        if let updatePeriod {
            task = Self.makeTask(
                eventLoop, managedNetwork, ManagedNetwork.networkFirstUpdateDelay, updatePeriod, shard, realm,
                plaintextOnly)
        }
    }

    private static func makeTask(
        _ eventLoop: NIOCore.EventLoopGroup,
        _ managedNetwork: ManagedNetwork,
        _ startDelay: Duration?,
        _ updatePeriod: UInt64,
        _ shard: UInt64,
        _ realm: UInt64,
        _ plaintextOnly: Bool
    ) -> Task<(), Error> {
        return Task {
            if let startDelay {
                try await Task.sleep(nanoseconds: startDelay.seconds * 1_000_000_000)
            }

            while true {
                print("Updating network")
                let start = Timestamp.now

                do {
                    let mirror = managedNetwork.mirror.load(ordering: .relaxed)
                    let addressBook = try await NodeAddressBookQuery(
                        FileId.getAddressBookFileIdFor(shard: shard, realm: realm)
                    ).executeChannel(mirror.channel)

                    // Filter to plaintext-only endpoints if this is a plaintext-only client
                    let filtered: NodeAddressBook
                    if plaintextOnly {
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

                    _ = managedNetwork.primary.readCopyUpdate { network in
                        Network.withAddressBook(network, eventLoop.next(), filtered)
                    }

                } catch let error as HError {
                    // todo: log the error
                    _ = error
                }

                let elapsed = (Timestamp.now - start).seconds * 1_000_000_000
                if elapsed < updatePeriod {
                    try await Task.sleep(nanoseconds: updatePeriod - elapsed)
                }
            }
        }
    }

    internal func setUpdatePeriod(_ duration: UInt64?, _ shard: UInt64, _ realm: UInt64) {
        self.task?.cancel()

        if let updatePeriod = duration {
            self.task = Self.makeTask(eventLoop, managedNetwork, nil, updatePeriod, shard, realm, plaintextOnly)
        }
    }

    private let eventLoop: NIOCore.EventLoopGroup
    private let managedNetwork: ManagedNetwork
    private let plaintextOnly: Bool
    private var task: Task<(), Error>?

    deinit {
        task?.cancel()
    }
}

extension ManagedAtomic {
    internal func readCopyUpdate(_ body: (Value) throws -> Value) rethrows -> Value {
        while true {
            let old = load(ordering: .acquiring)
            let new = try body(old)
            let (success, _) = compareExchange(expected: old, desired: new, ordering: .acquiringAndReleasing)

            if success {
                return new
            }
        }
    }
}
