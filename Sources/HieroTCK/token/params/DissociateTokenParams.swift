// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `dissociateToken` JSON-RPC method call.
///
/// This struct captures optional fields such as the `accountId` to dissociate from,
/// the list of `tokenIds` to dissociate, and any transaction-level metadata.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct DissociateTokenParams {

    internal var accountId: String? = nil
    internal var tokenIds: [String]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .dissociateToken
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.accountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "accountId", from: params, for: method)
        self.tokenIds = try JSONRPCParser.getOptionalPrimitiveListIfPresent(name: "tokenIds", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams", from: params, for: method, using: CommonTransactionParams.init)
    }
}
