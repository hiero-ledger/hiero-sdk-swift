// SPDX-License-Identifier: Apache-2.0

/// An immutable representation of a registered node as stored in network state.
///
/// Registered nodes are created via `RegisteredNodeCreateTransaction` and represent
/// block nodes, mirror nodes, RPC relays, and other registered network participants.
/// This type is returned by `RegisteredNodeAddressBookQuery` once that query is available.
public struct RegisteredNode {
    /// The unique identifier assigned to this registered node by the network.
    public let registeredNodeId: UInt64

    /// The administrative key controlled by the node operator.
    public let adminKey: Key

    /// An optional short description of the node.
    public let description: String?

    /// The list of service endpoints published by this registered node.
    public let serviceEndpoints: [RegisteredServiceEndpoint]

    public init(
        registeredNodeId: UInt64,
        adminKey: Key,
        description: String? = nil,
        serviceEndpoints: [RegisteredServiceEndpoint] = []
    ) {
        self.registeredNodeId = registeredNodeId
        self.adminKey = adminKey
        self.description = description
        self.serviceEndpoints = serviceEndpoints
    }
}
