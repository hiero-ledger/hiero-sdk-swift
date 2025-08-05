// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `grantTokenKyc` JSON-RPC method call.
///
/// This struct captures the optional parameters needed to grant KYC (Know Your Customer)
/// status to an account for a specific token, including the `tokenId`, the `accountId`,
/// and any common transaction parameters.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct GrantTokenKycParams {

    internal var tokenId: String? = nil
    internal var accountId: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .grantTokenKyc
        guard let params = try JSONRPCParser.getOptionalParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "tokenId", from: params, for: method)
        self.accountId = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "accountId", from: params, for: method)
        self.commonTransactionParams = try CommonTransactionParams(
            from: try JSONRPCParser.getOptionalJsonParameterIfPresent(
                name: "commonTransactionParams", from: params, for: method),
            for: method)
    }
}
