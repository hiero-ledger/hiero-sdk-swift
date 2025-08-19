// SPDX-License-Identifier: Apache-2.0

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
            name: "denominatingTokenId",
            from: params,
            for: method)
    }
}
