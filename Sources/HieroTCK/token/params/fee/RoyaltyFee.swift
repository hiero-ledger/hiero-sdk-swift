// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Represents a royalty fee parsed from JSON-RPC parameters.
///
/// A `RoyaltyFee` defines a fraction of value owed to the fee collector upon NFT transfers,
/// calculated as `numerator / denominator`. Optionally, a fallback fixed fee may be provided
/// to apply in situations where fractional value cannot be determined (e.g., no sale price).
internal struct RoyaltyFee {

    internal var numerator: String
    internal var denominator: String
    internal var fallbackFee: FixedFee? = nil

    internal init(from params: [String: JSONObject], for funcName: JSONRPCMethod) throws {
        self.numerator = try JSONRPCParser.getRequiredJsonParameter(name: "numerator", from: params, for: funcName)
        print(numerator)
        self.denominator = try JSONRPCParser.getRequiredJsonParameter(name: "denominator", from: params, for: funcName)
        print(denominator)
        self.fallbackFee = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "fallbackFee", from: params, for: funcName, using: FixedFee.init)
        print(fallbackFee)
    }

    /// Converts this `RoyaltyFee` type into a Hiero `RoyaltyFee` type.
    ///
    /// - Parameters:
    ///   - feeCollectorAccountId: The `AccountId` of the account collecting the fee.
    ///   - feeCollectorsExempt: Whether all fee collectors are exempt from fees.
    ///   - funcName: The JSON-RPC method name, used for error context if parsing fails.
    /// - Returns: A `Hiero.RoyaltyFee` instance.
    /// - Throws: `JSONError.invalidParams` if any value is malformed.
    internal func toHieroCustomFee(
        feeCollectorAccountId: AccountId, feeCollectorsExempt: Bool, for funcName: JSONRPCMethod
    )
        throws -> Hiero.RoyaltyFee
    {
        return Hiero.RoyaltyFee(
            numerator: try CommonParamsParser.getNumerator(from: self.numerator, for: funcName),
            denominator: try CommonParamsParser.getDenominator(from: self.denominator, for: funcName),
            fallbackFee: try self.fallbackFee?.toHieroCustomFee(
                feeCollectorAccountId: feeCollectorAccountId,
                feeCollectorsExempt: feeCollectorsExempt,
                for: funcName),
            feeCollectorAccountId: feeCollectorAccountId,
            allCollectorsAreExempt: feeCollectorsExempt
        )

    }
}
