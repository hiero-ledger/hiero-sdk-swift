// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `unpauseToken` JSON-RPC method call.
///
/// This struct encapsulates the optional parameters required to unpause a previously paused token,
/// including the token ID and any common transaction configuration.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct UnpauseTokenParams {

    internal var tokenId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .unpauseToken
        guard let params = try JSONRPCParser.getOptionalParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "tokenId", from: params, for: method)
        self.commonTransactionParams = try CommonTransactionParams(
            from: try JSONRPCParser.getOptionalJsonParameterIfPresent(
                name: "commonTransactionParams", from: params, for: method),
            for: method)
    }
}
