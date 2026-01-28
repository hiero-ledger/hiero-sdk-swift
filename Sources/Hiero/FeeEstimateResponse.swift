// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The response containing the estimated transaction fees.
public struct FeeEstimateResponse: Sendable, Equatable, Hashable {
    /// The mode that was used to calculate the fees.
    public let mode: FeeEstimateMode

    /// The network fee component which covers the cost of gossip, consensus,
    /// signature verifications, fee payment, and storage.
    public let networkFee: NetworkFee

    /// The node fee component which is to be paid to the node that submitted the
    /// transaction to the network.
    public let nodeFee: FeeEstimate

    /// The service fee component which covers execution costs, state saved in the
    /// Merkle tree, and additional costs to the blockchain storage.
    public let serviceFee: FeeEstimate

    /// An array of strings for any caveats (e.g., ["Fallback to worst-case due to missing state"]).
    public let notes: [String]

    /// The sum of the network, node, and service subtotals in tinycents.
    public let total: UInt64

    /// Create a new `FeeEstimateResponse`.
    ///
    /// - Parameters:
    ///   - mode: The mode that was used to calculate the fees.
    ///   - networkFee: The network fee component.
    ///   - nodeFee: The node fee component.
    ///   - serviceFee: The service fee component.
    ///   - notes: An array of strings for any caveats.
    ///   - total: The sum of the network, node, and service subtotals in tinycents.
    public init(
        mode: FeeEstimateMode,
        networkFee: NetworkFee,
        nodeFee: FeeEstimate,
        serviceFee: FeeEstimate,
        notes: [String],
        total: UInt64
    ) {
        self.mode = mode
        self.networkFee = networkFee
        self.nodeFee = nodeFee
        self.serviceFee = serviceFee
        self.notes = notes
        self.total = total
    }

    /// Parse a `FeeEstimateResponse` from JSON data returned by the mirror node REST API.
    ///
    /// - Parameters:
    ///   - data: The JSON data from the REST API response.
    ///   - mode: The fee estimate mode that was used in the request.
    /// - Returns: A parsed `FeeEstimateResponse`.
    /// - Throws: `HError.basicParse` if the JSON cannot be deserialized.
    /// - Note: Missing or malformed fields default to zero/empty values rather than throwing.
    ///   This is intentional to handle optional fields in the API response gracefully.
    internal static func fromJson(_ data: Data, mode: FeeEstimateMode) throws -> FeeEstimateResponse {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw HError.basicParse("Unable to decode FeeEstimateResponse JSON")
        }

        return try fromJson(json, mode: mode)
    }

    /// Parse a `FeeEstimateResponse` from a JSON dictionary.
    ///
    /// - Parameters:
    ///   - json: The JSON dictionary.
    ///   - mode: The fee estimate mode that was used in the request.
    /// - Returns: A parsed `FeeEstimateResponse`.
    /// - Note: Missing or malformed fields default to zero/empty values rather than throwing.
    ///   This is intentional to handle optional fields in the API response gracefully.
    internal static func fromJson(_ json: [String: Any], mode: FeeEstimateMode) throws -> FeeEstimateResponse {
        let networkFee = try NetworkFee.fromJson(json["network_fee"] as? [String: Any] ?? [:])
        let nodeFee = try FeeEstimate.fromJson(json["node_fee"] as? [String: Any] ?? [:])
        let serviceFee = try FeeEstimate.fromJson(json["service_fee"] as? [String: Any] ?? [:])
        let notes = json["notes"] as? [String] ?? []
        let total = (json["total"] as? NSNumber)?.uint64Value ?? 0

        return FeeEstimateResponse(
            mode: mode,
            networkFee: networkFee,
            nodeFee: nodeFee,
            serviceFee: serviceFee,
            notes: notes,
            total: total
        )
    }
}
