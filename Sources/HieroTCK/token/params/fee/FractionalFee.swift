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

    internal init(from params: [String: JSONObject], for funcName: JSONRPCMethod) throws {
        self.numerator = try JSONRPCParser.getRequiredJsonParameter(name: "numerator", from: params, for: funcName)
        self.denominator = try JSONRPCParser.getRequiredJsonParameter(name: "denominator", from: params, for: funcName)
        self.minimumAmount = try JSONRPCParser.getRequiredJsonParameter(
            name: "minimumAmount", from: params, for: funcName)
        self.maximumAmount = try JSONRPCParser.getRequiredJsonParameter(
            name: "maximumAmount", from: params, for: funcName)
        self.assessmentMethod = try JSONRPCParser.getRequiredJsonParameter(
            name: "assessmentMethod", from: params, for: funcName)
    }

    /// Converts this `FractionalFee` type into a Hiero `FractionalFee` type.
    ///
    /// Validates numeric values and parses the assessment method into the corresponding SDK enum.
    ///
    /// - Parameters:
    ///   - feeCollectorAccountId: The `AccountId` of the account collecting the fee.
    ///   - feeCollectorsExempt: Whether all fee collectors are exempt from fees.
    ///   - funcName: The JSON-RPC method name, used for error context if parsing fails.
    /// - Returns: A `Hiero.FractionalFee` object.
    /// - Throws: `JSONError.invalidParams` if validation fails.
    internal func toHieroCustomFee(
        feeCollectorAccountId: AccountId, feeCollectorsExempt: Bool, for funcName: JSONRPCMethod
    )
        throws -> Hiero.FractionalFee
    {
        guard self.assessmentMethod == "inclusive" || self.assessmentMethod == "exclusive" else {
            throw JSONError.invalidParams("\(funcName.rawValue): assessmentMethod MUST be 'inclusive' or 'exclusive'.")
        }

        /// Unwrap of self.minimumAmount and self.maximumAmount can be safely forced since they are not optional.
        return Hiero.FractionalFee(
            numerator: try CommonParamsParser.getNumerator(from: self.numerator, for: funcName),
            denominator: try CommonParamsParser.getDenominator(from: self.denominator, for: funcName),
            minimumAmount: try CommonParamsParser.getSdkUInt64IfPresent(
                name: "minimumAmount", from: self.minimumAmount, for: funcName)!,
            maximumAmount: try CommonParamsParser.getSdkUInt64IfPresent(
                name: "maximumAmount", from: self.maximumAmount, for: funcName)!,
            assessmentMethod: self.assessmentMethod == "inclusive"
                ? Hiero.FractionalFee.FeeAssessmentMethod.inclusive
                : Hiero.FractionalFee.FeeAssessmentMethod.exclusive,
            feeCollectorAccountId: feeCollectorAccountId,
            allCollectorsAreExempt: feeCollectorsExempt
        )
    }
}
