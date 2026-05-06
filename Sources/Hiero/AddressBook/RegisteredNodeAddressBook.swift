// SPDX-License-Identifier: Apache-2.0

/// A collection of registered nodes returned by a `RegisteredNodeAddressBookQuery`.
///
/// Registered nodes include block nodes, mirror nodes, RPC relays, and other registered
/// network participants published on-chain via `RegisteredNodeCreateTransaction`.
public struct RegisteredNodeAddressBook {
    /// The list of registered nodes in this address book.
    public let registeredNodes: [RegisteredNode]

    /// Creates an address book with the given list of registered nodes.
    public init(registeredNodes: [RegisteredNode] = []) {
        self.registeredNodes = registeredNodes
    }
}
