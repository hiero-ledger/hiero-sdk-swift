// SPDX-License-Identifier: Apache-2.0

/// Represents a fungible token allowance granted from an owner to a spender.
///
/// This struct includes the `tokenId` of the token and the `amount` the spender
/// is permitted to use. Both fields are required and parsed from the JSON-RPC parameters.
internal struct TokenAllowance {

    internal var tokenId: String
    internal var amount: String

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.tokenId = try JSONRPCParser.getRequiredParameter(name: "tokenId", from: params, for: method)
        self.amount = try JSONRPCParser.getRequiredParameter(name: "amount", from: params, for: method)
    }
}
