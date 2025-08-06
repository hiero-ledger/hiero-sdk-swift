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
            targets: targets,
            eventLoop: eventLoop,
            transportSecurity: .tls(
                .makeClientDefault(compatibleWith: eventLoop)
            )
        )
    }

    private convenience init(
        targets: Set<HostAndPort>,
        eventLoop: EventLoopGroup,
        transportSecurity: GRPCChannelPool.Configuration.TransportSecurity
    ) {
        let targetSecurityPairs = targets.map { hostAndPort in
            let security: GRPCChannelPool.Configuration.TransportSecurity =
                (hostAndPort.port == NodeConnection.tlsPort)
                ? .tls(.makeClientDefault(compatibleWith: eventLoop)) : .plaintext
            return (GRPC.ConnectionTarget.host(hostAndPort.host, port: Int(hostAndPort.port)), security)
        }

        self.init(
            channel: ChannelBalancer(
                eventLoop: eventLoop.next(),
                targetSecurityPairs
            ),
            targets: targets
        )
    }

    internal convenience init(targets: [String], eventLoop: EventLoopGroup) {
        self.init(
            targets: targets, eventLoop: eventLoop,
            transportSecurity: .tls(.makeClientDefault(compatibleWith: eventLoop)))
    }

    internal convenience init(
        targets: [String],
        eventLoop: EventLoopGroup,
        transportSecurity: GRPCChannelPool.Configuration.TransportSecurity
    ) {
        let hostAndPorts = Set(
            targets.lazy.map { target in
                let (host, port) = target.splitOnce(on: ":") ?? (target[...], nil)
                return HostAndPort(host: String(host), port: port.flatMap { UInt16($0) } ?? 443)
            }
        )

        let isLocal = targets.allSatisfy {
            $0.contains("localhost") || $0.contains("127.0.0.1")
        }

        let mirrorChannel = ChannelBalancer(
            eventLoop: eventLoop.next(),
            hostAndPorts.map {
                let security: GRPCChannelPool.Configuration.TransportSecurity =
                    isLocal
                    ? .plaintext
                    : .tls(.makeClientDefault(compatibleWith: eventLoop))

                return (.host($0.host, port: Int($0.port)), security)
            }
        )

        self.init(channel: mirrorChannel, targets: hostAndPorts)
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
        let targetSecurityPairs = Targets.localhost.map { hostAndPort in
            let security: GRPCChannelPool.Configuration.TransportSecurity =
                (hostAndPort.port == NodeConnection.tlsPort)
                ? .tls(.makeClientDefault(compatibleWith: eventLoop)) : .plaintext
            return (GRPC.ConnectionTarget.host(hostAndPort.host, port: Int(hostAndPort.port)), security)
        }

        return Self(
            channel: ChannelBalancer(
                eventLoop: eventLoop.next(),
                targetSecurityPairs
            ),
            targets: Targets.localhost
        )
    }
}
