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

    internal init(from params: [String: JSONObject], for funcName: JSONRPCMethod) throws {
        self.accountId = try JSONRPCParser.getRequiredJsonParameter(name: "accountId", from: params, for: funcName)
        self.tokenId = try JSONRPCParser.getRequiredJsonParameter(name: "tokenId", from: params, for: funcName)
        self.amount = try JSONRPCParser.getRequiredJsonParameter(name: "amount", from: params, for: funcName)
        self.decimals = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "decimals", from: params, for: funcName)
    }
}
