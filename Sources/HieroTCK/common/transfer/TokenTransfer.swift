// SPDX-License-Identifier: Apache-2.0

/// Represents a fungible token transfer parsed from a JSON-RPC request.
///
/// This struct is used to decode and validate a single token transfer entry. It includes:
/// - `accountId`: The ID of the account receiving or sending the tokens.
/// - `tokenId`: The ID of the token being transferred.
/// - `amount`: The number of tokens to transfer, represented as a string to preserve precision.
/// - `decimals`: The number of decimal places used to interpret the `amount`.
internal struct TokenTransfer {

    internal var accountId: String
    internal var tokenId: String
    internal var amount: String
    internal var decimals: UInt32? = nil

    internal init(from params: [String: JSONObject], for method: JSONRPCMethod) throws {
        self.accountId = try JSONRPCParser.getRequiredParameter(name: "accountId", from: params, for: method)
        self.tokenId = try JSONRPCParser.getRequiredParameter(name: "tokenId", from: params, for: method)
        self.amount = try JSONRPCParser.getRequiredParameter(name: "amount", from: params, for: method)
        self.decimals = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "decimals", from: params, for: method)
    }
}
