// SPDX-License-Identifier: Apache-2.0

/// Represents an NFT allowance granted from an owner to a spender.
///
/// This struct supports specifying either a list of individual serial numbers
/// or a blanket approval via the `approvedForAll` flag. An optional
/// `delegateSpenderAccountId` may also be provided for delegated allowances.
///
/// Initialized from a parsed JSON-RPC parameters dictionary, requiring the `"tokenId"`
/// field and optionally accepting `"serialNumbers"`, `"approvedForAll"`, and `"delegateSpenderAccountId"`.
internal struct NftAllowance {

    internal var tokenId: String
    internal var serialNumbers: [String]? = nil
    internal var approvedForAll: Bool? = nil
    internal var delegateSpenderAccountId: String? = nil

    internal init(from params: [String: JSONObject], for funcName: JSONRPCMethod) throws {
        self.tokenId = try JSONRPCParser.getRequiredJsonParameter(name: "tokenId", from: params, for: funcName)
        self.serialNumbers = try JSONRPCParser.getOptionalPrimitiveListIfPresent(
            name: "serialNumbers", from: params, for: funcName)
        self.approvedForAll = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "approvedForAll", from: params, for: funcName)
        self.delegateSpenderAccountId = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "delegateSpenderAccountId", from: params, for: funcName)
    }
}
