// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `freezeToken` JSON-RPC method call.
///
/// This struct captures optional parameters such as the `tokenId` to freeze,
/// the `accountId` whose token relationship is to be frozen, and common
/// transaction metadata.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct FreezeTokenParams {

    internal var tokenId: String? = nil
    internal var accountId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .freezeToken
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalParameterIfPresent(name: "tokenId", from: params, for: method)
        self.accountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "accountId",
            from: params,
            for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
