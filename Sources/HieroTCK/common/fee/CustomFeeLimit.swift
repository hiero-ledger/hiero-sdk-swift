// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Represents a custom fee limit from a JSON-RPC request.
///
/// A custom fee limit specifies the maximum fees a payer is willing to pay
/// for a transaction (e.g., topic message submission).
internal struct CustomFeeLimit: JSONRPCListElementDecodable {
    internal static let elementName = "custom fee limit"

    internal var payerId: String
    internal var fixedFees: [FixedFee]

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.payerId = try JSONRPCParser.getRequiredParameter(name: "payerId", from: params, for: method)
        self.fixedFees = try JSONRPCParser.getRequiredCustomObjectList(
            name: "fixedFees",
            from: params,
            for: method,
            decoder: FixedFee.jsonObjectDecoder(for: method))
    }

    /// Converts this param to a Hiero `CustomFeeLimit`.
    internal func toHiero(for method: JSONRPCMethod) throws -> Hiero.CustomFeeLimit {
        let payerId = try AccountId.fromString(payerId)
        let customFees = try fixedFees.map { fee -> CustomFixedFee in
            let amount = try JSONRPCParam.parseUInt64ReinterpretingSigned(name: "amount", from: fee.amount, for: method)
            let denominatingTokenId = try fee.denominatingTokenId.flatMap { try TokenId.fromString($0) }
            return CustomFixedFee(amount, payerId, denominatingTokenId, false)
        }
        return Hiero.CustomFeeLimit(payerId: payerId, customFees: customFees)
    }
}
