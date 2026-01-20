// SPDX-License-Identifier: Apache-2.0

/// Represents a royalty fee parsed from JSON-RPC parameters.
///
/// A `RoyaltyFee` defines a fraction of value owed to the fee collector upon NFT transfers,
/// calculated as `numerator / denominator`. Optionally, a fallback fixed fee may be provided
/// to apply in situations where fractional value cannot be determined (e.g., no sale price).
internal struct RoyaltyFee {

    internal var numerator: String
    internal var denominator: String
    internal var fallbackFee: FixedFee? = nil

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.numerator = try JSONRPCParser.getRequiredParameter(name: "numerator", from: params, for: method)
        self.denominator = try JSONRPCParser.getRequiredParameter(name: "denominator", from: params, for: method)
        self.fallbackFee = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "fallbackFee",
            from: params,
            for: method,
            using: FixedFee.init)
    }
}
