// SPDX-License-Identifier: Apache-2.0

/// Represents a fractional fee parsed from JSON-RPC parameters.
///
/// A `FractionalFee` defines a fee as a fraction of the transferred amount,
/// governed by a numerator/denominator ratio and bounded by minimum and maximum limits.
/// The fee assessment behavior is controlled via the `assessmentMethod` field, which must
/// be either `"inclusive"` or `"exclusive"`.
internal struct FractionalFee {

    internal var numerator: String
    internal var denominator: String
    internal var minimumAmount: String
    internal var maximumAmount: String
    internal var assessmentMethod: String

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.numerator = try JSONRPCParser.getRequiredParameter(name: "numerator", from: params, for: method)
        self.denominator = try JSONRPCParser.getRequiredParameter(name: "denominator", from: params, for: method)
        self.minimumAmount = try JSONRPCParser.getRequiredParameter(
            name: "minimumAmount",
            from: params,
            for: method)
        self.maximumAmount = try JSONRPCParser.getRequiredParameter(
            name: "maximumAmount",
            from: params,
            for: method)
        self.assessmentMethod = try JSONRPCParser.getRequiredParameter(
            name: "assessmentMethod",
            from: params,
            for: method)
    }
}
