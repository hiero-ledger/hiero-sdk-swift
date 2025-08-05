// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `deleteToken` JSON-RPC method call.
///
/// This struct handles optional input for deleting a token, including the token's identifier
/// and any associated transaction-level configuration.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct DeleteTokenParams {

    internal var tokenId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .deleteToken
        guard let params = try JSONRPCParser.getOptionalParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "tokenId", from: params, for: method)
        self.commonTransactionParams = try CommonTransactionParams(
            from: try JSONRPCParser.getOptionalJsonParameterIfPresent(
                name: "commonTransactionParams", from: params, for: method),
            for: method)

    }
}
