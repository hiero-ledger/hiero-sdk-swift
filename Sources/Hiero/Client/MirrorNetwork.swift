// SPDX-License-Identifier: Apache-2.0

import Atomics
import GRPC
import NIOCore

internal final class MirrorNetwork: AtomicReference, Sendable {
    private enum Targets {
        static let mainnet: Set<HostAndPort> = [.init(host: "mainnet-public.mirrornode.hedera.com", port: 443)]
        static let testnet: Set<HostAndPort> = [.init(host: "testnet.mirrornode.hedera.com", port: 443)]
        static let previewnet: Set<HostAndPort> = [.init(host: "previewnet.mirrornode.hedera.com", port: 443)]
        static let localhost: Set<HostAndPort> = [.init(host: "127.0.0.1", port: 5600)]
    }

    internal let channel: ChannelBalancer
    internal let addresses: Set<HostAndPort>

    private init(channel: ChannelBalancer, targets: Set<HostAndPort>) {
        self.channel = channel
        self.addresses = targets
    }

    private convenience init(targets: Set<HostAndPort>, eventLoop: EventLoopGroup) {
        self.init(
            channel: ChannelBalancer(
                eventLoop: eventLoop.next(),
                targets.map { .hostAndPort($0.host, Int($0.port)) },
                transportSecurity: .tls(
                    .makeClientDefault(compatibleWith: eventLoop)
                )
            ),
            targets: targets
        )
    }

    internal convenience init(targets: [String], eventLoop: EventLoopGroup) {
        let targets = Set(
            targets.lazy.map { target in
                let (host, port) = target.splitOnce(on: ":") ?? (target[...], nil)

                return HostAndPort(host: String(host), port: port.flatMap { UInt16($0) } ?? 443)
            })

        self.init(targets: targets, eventLoop: eventLoop)
    }

    internal static func mainnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(targets: Targets.mainnet, eventLoop: eventLoop)
    }

    internal static func testnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(targets: Targets.testnet, eventLoop: eventLoop)
    }

    internal static func previewnet(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(targets: Targets.previewnet, eventLoop: eventLoop)
    }

    internal static func localhost(_ eventLoop: NIOCore.EventLoopGroup) -> Self {
        Self(targets: Targets.localhost, eventLoop: eventLoop)
    }
}
