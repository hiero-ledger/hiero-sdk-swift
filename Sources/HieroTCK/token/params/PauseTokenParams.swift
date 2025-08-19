// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `pauseToken` JSON-RPC method call.
///
/// This struct holds optional parameters used when pausing a token.
/// It includes the `tokenId` of the token to pause and any common
/// transaction metadata.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct PauseTokenParams {

    internal var tokenId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .pauseToken
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalParameterIfPresent(name: "tokenId", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
