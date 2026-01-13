// SPDX-License-Identifier: Apache-2.0

/// Parameters for the `getTokenInfo` JSON-RPC method.
internal struct GetTokenInfoParams {

    internal var tokenId: String? = nil
    internal var queryPayment: String? = nil
    internal var maxQueryPayment: String? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .getTokenInfo
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "tokenId", from: params, for: method)
        self.queryPayment = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "queryPayment", from: params, for: method)
        self.maxQueryPayment = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "maxQueryPayment", from: params, for: method)
    }
}
