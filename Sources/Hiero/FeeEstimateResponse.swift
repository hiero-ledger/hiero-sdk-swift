// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The response containing the estimated transaction fees.
public struct FeeEstimateResponse: Sendable, Equatable, Hashable {
    /// The high-volume pricing multiplier per HIP-1313. A value of 1 indicates no
    /// high-volume pricing. A value greater than 1 applies when the transaction's
    /// highVolume flag is true and throttle utilization is non-zero.
    public let highVolumeMultiplier: UInt64

    /// The network fee component which covers the cost of gossip, consensus,
    /// signature verifications, fee payment, and storage.
    public let network: NetworkFee

    /// The node fee component which is to be paid to the node that submitted the
    /// transaction to the network.
    public let node: FeeEstimate

    /// The service fee component which covers execution costs, state saved in the
    /// Merkle tree, and additional costs to the blockchain storage.
    public let service: FeeEstimate

    /// The sum of the network, node, and service subtotals in tinycents.
    public let total: UInt64

    /// Create a new `FeeEstimateResponse`.
    public init(
        highVolumeMultiplier: UInt64 = 1,
        network: NetworkFee,
        node: FeeEstimate,
        service: FeeEstimate,
        total: UInt64
    ) {
        self.highVolumeMultiplier = highVolumeMultiplier
        self.network = network
        self.node = node
        self.service = service
        self.total = total
    }

    /// Parse a `FeeEstimateResponse` from JSON data returned by the mirror node REST API.
    internal static func fromJson(_ data: Data) throws -> FeeEstimateResponse {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw HError.basicParse("Unable to decode FeeEstimateResponse JSON")
        }
        return try fromJson(json)
    }

    /// Parse a `FeeEstimateResponse` from a JSON dictionary.
    ///
    /// Missing or malformed fields default to zero/empty values rather than throwing.
    internal static func fromJson(_ json: [String: Any]) throws -> FeeEstimateResponse {
        let highVolumeMultiplier = (json["high_volume_multiplier"] as? NSNumber)?.uint64Value ?? 1
        let networkFee = try NetworkFee.fromJson(json["network"] as? [String: Any] ?? [:])
        let nodeFee = try FeeEstimate.fromJson(json["node"] as? [String: Any] ?? [:])
        let serviceFee = try FeeEstimate.fromJson(json["service"] as? [String: Any] ?? [:])
        let total = (json["total"] as? NSNumber)?.uint64Value ?? 0

        return FeeEstimateResponse(
            highVolumeMultiplier: highVolumeMultiplier,
            network: networkFee,
            node: nodeFee,
            service: serviceFee,
            total: total
        )
    }
}
