// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `wipeToken` JSON-RPC method call.
///
/// This struct encapsulates optional fields for wiping fungible or non-fungible tokens
/// from a specified account, including the token ID, account ID, wipe amount (for fungible tokens),
/// serial numbers (for NFTs), and standard transaction metadata.
///
/// - Note: Either `amount` or `serialNumbers` should be provided, depending on token type.
internal struct WipeTokenParams {

    internal var tokenId: String?
    internal var accountId: String?
    internal var amount: String?
    internal var serialNumbers: [String]?
    internal var commonTransactionParams: CommonTransactionParams?

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .wipeToken
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalParameterIfPresent(name: "tokenId", from: params, for: method)
        self.accountId = try JSONRPCParser.getOptionalParameterIfPresent(name: "accountId", from: params, for: method)
        self.amount = try JSONRPCParser.getOptionalParameterIfPresent(name: "amount", from: params, for: method)
        self.serialNumbers = try JSONRPCParser.getOptionalPrimitiveListIfPresent(
            name: "serialNumbers",
            from: params,
            for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
