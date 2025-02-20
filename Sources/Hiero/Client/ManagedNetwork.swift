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
    internal init(eventLoop: NIOCore.EventLoopGroup, managedNetwork: ManagedNetwork, updatePeriod: UInt64?) {
        self.managedNetwork = managedNetwork
        self.eventLoop = eventLoop

        if let updatePeriod {
            task = Self.makeTask(eventLoop, managedNetwork, ManagedNetwork.networkFirstUpdateDelay, updatePeriod)
        }
    }

    private static func makeTask(
        _ eventLoop: NIOCore.EventLoopGroup,
        _ managedNetwork: ManagedNetwork,
        _ startDelay: Duration?,
        _ updatePeriod: UInt64
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
                    let addressBook = try await NodeAddressBookQuery(FileId.addressBook).executeChannel(mirror.channel)

                    _ = managedNetwork.primary.readCopyUpdate {
                        Network.withAddressBook($0, eventLoop.next(), addressBook)
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

    internal func setUpdatePeriod(_ duration: UInt64?) {
        self.task?.cancel()

        if let updatePeriod = duration {
            self.task = Self.makeTask(eventLoop, managedNetwork, nil, updatePeriod)
        }
    }

    private let eventLoop: NIOCore.EventLoopGroup
    private let managedNetwork: ManagedNetwork
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
