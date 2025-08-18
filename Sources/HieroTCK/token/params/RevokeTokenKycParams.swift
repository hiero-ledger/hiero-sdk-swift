// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `revokeTokenKyc` JSON-RPC method call.
///
/// This struct contains optional parameters for revoking KYC status on a token.
/// It includes the token ID, the account ID from which KYC is being revoked,
/// and any common transaction metadata.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct RevokeTokenKycParams {

    internal var tokenId: String? = nil
    internal var accountId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .revokeTokenKyc
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalParameterIfPresent(name: "tokenId", from: params, for: method)
        self.accountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "accountId", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams", from: params, for: method, using: CommonTransactionParams.init)
    }
}
