// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Struct to hold the parameters of a custom fee.
internal struct CustomFee {

    internal var feeCollectorAccountId: String
    internal var feeCollectorsExempt: Bool
    internal var fixedFee: FixedFee? = nil
    internal var fractionalFee: FractionalFee? = nil
    internal var royaltyFee: RoyaltyFee? = nil

    internal init(_ params: [String: JSONObject], _ funcName: JSONRPCMethod) throws {
        self.feeCollectorAccountId = try getRequiredJsonParameter("feeCollectorAccountId", params, funcName)
        self.feeCollectorsExempt = try getRequiredJsonParameter("feeCollectorsExempt", params, funcName)

        if let fixedFee: [String: JSONObject] = try getOptionalJsonParameter("fixedFee", params, funcName) {
            self.fixedFee = try FixedFee(fixedFee, funcName)
        }
        if let fractionalFee: [String: JSONObject] = try getOptionalJsonParameter("fractionalFee", params, funcName) {
            self.fractionalFee = try FractionalFee(fractionalFee, funcName)
        }
        if let royaltyFee: [String: JSONObject] = try getOptionalJsonParameter("royaltyFee", params, funcName) {
            self.royaltyFee = try RoyaltyFee(royaltyFee, funcName)
        }
    }

    internal func toHederaCustomFee(_ funcName: JSONRPCMethod) throws -> AnyCustomFee {
        let feeCollectorAccountId = try AccountId.fromString(self.feeCollectorAccountId)
        let feeCollectorsExempt = self.feeCollectorsExempt

        /// Make sure only one of the three fee types is provided.
        guard
            (self.fixedFee != nil && self.fractionalFee == nil && self.royaltyFee == nil)
                || (self.fixedFee == nil && self.fractionalFee != nil && self.royaltyFee == nil)
                || (self.fixedFee == nil && self.fractionalFee == nil && self.royaltyFee != nil)
        else {
            throw JSONError.invalidParams("\(funcName.rawValue): one and only one fee type SHALL be provided.")
        }

        if let fixedFee = self.fixedFee {
            return AnyCustomFee.fixed(
                try fixedFee.toHederaFixedFee(feeCollectorAccountId, feeCollectorsExempt, funcName))
        } else if let fractionalFee = self.fractionalFee {
            return AnyCustomFee.fractional(
                try fractionalFee.toHederaFractionalFee(feeCollectorAccountId, feeCollectorsExempt, funcName))
        } else {
            /// Guaranteed at this point the fee is a royalty fee, just force the unpack.
            return AnyCustomFee.royalty(
                try self.royaltyFee!.toHederaRoyaltyFee(feeCollectorAccountId, feeCollectorsExempt, funcName))
        }
    }

}
