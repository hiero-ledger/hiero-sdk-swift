// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Struct to hold the parameters of a royalty fee.
internal struct RoyaltyFee {

    internal var numerator: String
    internal var denominator: String
    internal var fallbackFee: FixedFee? = nil

    internal init(_ params: [String: JSONObject], _ funcName: JSONRPCMethod) throws {
        self.numerator = try getRequiredJsonParameter("numerator", params, funcName)
        self.denominator = try getRequiredJsonParameter("denominator", params, funcName)
        self.fallbackFee = try getOptionalJsonParameter("fallbackFee", params, funcName).map {
            try FixedFee($0, funcName)
        }
    }

    /// Convert this RoyaltyFee to a Hedera RoyaltyFee.
    internal func toHederaRoyaltyFee(
        _ feeCollectorAccountID: AccountId, _ feeCollectorsExempt: Bool, _ funcName: JSONRPCMethod
    ) throws
        -> Hiero.RoyaltyFee
    {
        return Hiero.RoyaltyFee(
            numerator: try CommonParams.getNumerator(self.numerator, funcName),
            denominator: try CommonParams.getDenominator(self.denominator, funcName),
            fallbackFee: try self.fallbackFee?.toHederaFixedFee(feeCollectorAccountID, feeCollectorsExempt, funcName),
            feeCollectorAccountId: feeCollectorAccountID,
            allCollectorsAreExempt: feeCollectorsExempt
        )

    }
}
