// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Struct to hold the parameters of a fixed fee.
internal struct FixedFee {

    internal var amount: String
    internal var denominatingTokenID: String? = nil

    internal init(_ params: [String: JSONObject], _ funcName: JSONRPCMethod) throws {
        self.amount = try getRequiredJsonParameter("amount", params, funcName)
        self.denominatingTokenID = try getOptionalJsonParameter("denominatingTokenId", params, funcName)
    }

    /// Convert this FixedFee to a Hedera FixedFee.
    internal func toHederaFixedFee(
        _ feeCollectorAccountID: AccountId, _ feeCollectorsExempt: Bool, _ funcName: JSONRPCMethod
    ) throws
        -> Hiero.FixedFee
    {
        /// Unwrap of self.amount can be safely forced since self.amount isn't optional.
        return Hiero.FixedFee(
            amount: try CommonParams.getSdkUInt64(self.amount, "amount", funcName)!,
            denominatingTokenId: try CommonParams.getTokenId(self.denominatingTokenID),
            feeCollectorAccountId: feeCollectorAccountID,
            allCollectorsAreExempt: feeCollectorsExempt
        )
    }
}
