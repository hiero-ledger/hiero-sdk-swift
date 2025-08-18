// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Represents a fixed fee parsed from JSON-RPC parameters.
///
/// A fixed fee charges a specific amount of a token or HBAR per transaction.
/// If a `denominatingTokenID` is provided, the fee is charged in that token;
/// otherwise, it is charged in HBAR.
internal struct FixedFee {

    internal var amount: String
    internal var denominatingTokenID: String? = nil

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.amount = try JSONRPCParser.getRequiredParameter(name: "amount", from: params, for: method)
        self.denominatingTokenID = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "denominatingTokenId", from: params, for: method)
    }

    /// Converts this `FixedFee` type into a Hiero `FixedFee` type.
    ///
    /// This method performs type conversion and validation on internal fields, including parsing
    /// the string-based `amount` and optional `denominatingTokenID`. It also applies the
    /// provided fee collector identity and exemption flag to construct a complete SDK-compatible object.
    ///
    /// - Parameters:
    ///   - feeCollectorAccountId: The `AccountId` of the account collecting the fee.
    ///   - feeCollectorsExempt: Whether all fee collectors are exempt from fees.
    ///   - method: The JSON-RPC method name, used for error context if parsing fails.
    /// - Returns: A fully constructed Hiero `FixedFee` object.
    /// - Throws: `JSONError.invalidParams` if `amount` is invalid or token ID decoding fails.
    internal func toHieroCustomFee(
        feeCollectorAccountId: AccountId,
        feeCollectorsExempt: Bool,
        for method: JSONRPCMethod
    ) throws -> Hiero.FixedFee {
        // Unwrap of self.amount can be safely forced since self.amount isn't optional.
        return Hiero.FixedFee(
            amount: try CommonParamsParser.getAmount(
                from: self.amount,
                for: method,
                using: parseUInt64ReinterpretingSigned(name:from:for:)),
            denominatingTokenId: try CommonParamsParser.getTokenIdIfPresent(from: self.denominatingTokenID),
            feeCollectorAccountId: feeCollectorAccountId,
            allCollectorsAreExempt: feeCollectorsExempt
        )
    }
}
