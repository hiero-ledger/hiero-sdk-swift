// SPDX-License-Identifier: Apache-2.0

import Hiero

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

    /// Applies this token transfer to the given token transfer transaction.
    ///
    /// This method resolves the `accountId`, `tokenId`, and `amount` fields into SDK-level types
    /// and attaches them to the provided `AbstractTokenTransferTransaction`. If `decimals` are
    /// present, the transfer is applied using the decimal-aware API. The `approved` flag determines
    /// whether the transfer is marked as approved by the token owner for an allowance spender.
    ///
    /// - Parameters:
    ///   - tx: The token transfer transaction to modify.
    ///   - approved: Whether the transfer should be marked as approved via allowance.
    ///   - method: The JSON-RPC method name, used for error reporting during parsing.
    /// - Throws: `JSONError.invalidParams` if any parameter is invalid or cannot be parsed.
    internal func applyToTransaction<T: AbstractTokenTransferTransaction>(
        _ tx: inout T,
        approved: Bool,
        for method: JSONRPCMethod
    ) throws {
        let accountId = try AccountId.fromString(self.accountId)
        let tokenId = try TokenId.fromString(self.tokenId)
        let amount = try CommonParamsParser.getAmount(
            from: self.amount,
            for: method,
            using: JSONRPCParam.parseInt64(name:from:for:))

        if let decimals = self.decimals {
            _ =
                approved
                ? tx.approvedTokenTransferWithDecimals(tokenId, accountId, amount, decimals)
                : tx.tokenTransferWithDecimals(tokenId, accountId, amount, decimals)
        } else {
            _ =
                approved
                ? tx.approvedTokenTransfer(tokenId, accountId, amount)
                : tx.tokenTransfer(tokenId, accountId, amount)
        }
    }
}
