// SPDX-License-Identifier: Apache-2.0

import Hiero

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
            name: "minimumAmount", from: params, for: method)
        self.maximumAmount = try JSONRPCParser.getRequiredParameter(
            name: "maximumAmount", from: params, for: method)
        self.assessmentMethod = try JSONRPCParser.getRequiredParameter(
            name: "assessmentMethod", from: params, for: method)
    }

    /// Converts this `FractionalFee` type into a Hiero `FractionalFee` type.
    ///
    /// Validates numeric values and parses the assessment method into the corresponding SDK enum.
    ///
    /// - Parameters:
    ///   - feeCollectorAccountId: The `AccountId` of the account collecting the fee.
    ///   - feeCollectorsExempt: Whether all fee collectors are exempt from fees.
    ///   - method: The JSON-RPC method name, used for error context if parsing fails.
    /// - Returns: A Hiero `FractionalFee` object.
    /// - Throws: `JSONError.invalidParams` if validation fails.
    internal func toHieroCustomFee(
        feeCollectorAccountId: AccountId,
        feeCollectorsExempt: Bool,
        for method: JSONRPCMethod
    ) throws -> Hiero.FractionalFee {
        guard self.assessmentMethod == "inclusive" || self.assessmentMethod == "exclusive" else {
            throw JSONError.invalidParams("\(method.rawValue): assessmentMethod MUST be 'inclusive' or 'exclusive'.")
        }

        /// Unwrap of self.minimumAmount and self.maximumAmount can be safely forced since they are not optional.
        return Hiero.FractionalFee(
            numerator: try CommonParamsParser.getNumerator(from: self.numerator, for: method),
            denominator: try CommonParamsParser.getDenominator(from: self.denominator, for: method),
            minimumAmount: try parseUInt64ReinterpretingSigned(
                name: "minimumAmount", from: self.minimumAmount, for: method),
            maximumAmount: try parseUInt64ReinterpretingSigned(
                name: "maximumAmount", from: self.maximumAmount, for: method),
            assessmentMethod: self.assessmentMethod == "inclusive"
                ? Hiero.FractionalFee.FeeAssessmentMethod.inclusive
                : Hiero.FractionalFee.FeeAssessmentMethod.exclusive,
            feeCollectorAccountId: feeCollectorAccountId,
            allCollectorsAreExempt: feeCollectorsExempt
        )
    }
}
