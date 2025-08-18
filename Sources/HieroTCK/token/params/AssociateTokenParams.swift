// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `associateToken` JSON-RPC method call.
///
/// This struct captures optional inputs for associating one or more tokens with an account.
/// If no parameters are provided, defaults or validation may occur downstream.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct AssociateTokenParams {

    internal var accountId: String? = nil
    internal var tokenIds: [String]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .associateToken
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.accountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "accountId", from: params, for: method)
        self.tokenIds = try JSONRPCParser.getOptionalPrimitiveListIfPresent(
            name: "tokenIds", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams", from: params, for: method, using: CommonTransactionParams.init)

    }
}
