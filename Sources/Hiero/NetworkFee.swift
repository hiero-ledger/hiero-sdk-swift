// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The network fee component which covers the cost of gossip, consensus,
/// signature verifications, fee payment, and storage.
public struct NetworkFee: Sendable, Equatable, Hashable {
    /// Multiplied by the node fee to determine the total network fee.
    public let multiplier: UInt32

    /// The subtotal in tinycents for the network fee component which is calculated by
    /// multiplying the node subtotal by the network multiplier.
    public let subtotal: UInt64

    /// Create a new `NetworkFee`.
    ///
    /// - Parameters:
    ///   - multiplier: Multiplied by the node fee to determine the total network fee.
    ///   - subtotal: The subtotal in tinycents for the network fee component.
    public init(multiplier: UInt32, subtotal: UInt64) {
        self.multiplier = multiplier
        self.subtotal = subtotal
    }

    /// Parse a `NetworkFee` from a JSON dictionary.
    ///
    /// - Parameter json: The JSON dictionary containing `multiplier` and `subtotal` fields.
    /// - Returns: A parsed `NetworkFee`.
    /// - Note: Missing or malformed fields default to zero rather than throwing.
    ///   This is intentional to handle optional fields in the API response gracefully.
    internal static func fromJson(_ json: [String: Any]) throws -> NetworkFee {
        let multiplier = (json["multiplier"] as? NSNumber)?.uint32Value ?? 0
        let subtotal = (json["subtotal"] as? NSNumber)?.uint64Value ?? 0

        return NetworkFee(multiplier: multiplier, subtotal: subtotal)
    }
}
