// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Struct to hold the parameters of a fractional fee.
internal struct FractionalFee {

    internal var numerator: String
    internal var denominator: String
    internal var minimumAmount: String
    internal var maximumAmount: String
    internal var assessmentMethod: String

    internal init(_ params: [String: JSONObject], _ funcName: JSONRPCMethod) throws {
        self.numerator = try getRequiredJsonParameter("numerator", params, funcName)
        self.denominator = try getRequiredJsonParameter("denominator", params, funcName)
        self.minimumAmount = try getRequiredJsonParameter("minimumAmount", params, funcName)
        self.maximumAmount = try getRequiredJsonParameter("maximumAmount", params, funcName)
        self.assessmentMethod = try getRequiredJsonParameter("assessmentMethod", params, funcName)
    }

    /// Convert this FractionalFee to a Hedera FractionalFee.
    internal func toHederaFractionalFee(
        _ feeCollectorAccountID: AccountId, _ feeCollectorsExempt: Bool, _ funcName: JSONRPCMethod
    ) throws
        -> Hiero.FractionalFee
    {
        guard self.assessmentMethod == "inclusive" || self.assessmentMethod == "exclusive" else {
            throw JSONError.invalidParams("\(funcName.rawValue): assessmentMethod MUST be 'inclusive' or 'exclusive'.")
        }

        /// Unwrap of self.minimumAmount and self.maximumAmount can be safely forced since they are not optional.
        return Hiero.FractionalFee(
            numerator: try CommonParams.getNumerator(self.numerator, funcName),
            denominator: try CommonParams.getDenominator(self.denominator, funcName),
            minimumAmount: try CommonParams.getSdkUInt64(self.minimumAmount, "minimumAmount", funcName)!,
            maximumAmount: try CommonParams.getSdkUInt64(self.maximumAmount, "maximumAmount", funcName)!,
            assessmentMethod: self.assessmentMethod == "inclusive"
                ? Hiero.FractionalFee.FeeAssessmentMethod.inclusive
                : Hiero.FractionalFee.FeeAssessmentMethod.exclusive,
            feeCollectorAccountId: feeCollectorAccountID,
            allCollectorsAreExempt: feeCollectorsExempt
        )
    }
}
