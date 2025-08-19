// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `rejectToken` JSON-RPC method call.
///
/// This struct captures optional inputs for performing a token airdrop transaction.
/// It may include a list of token transfers and common transaction parameters to
/// customize execution. If no parameters are provided, defaults or validation may
/// occur downstream.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct RejectTokenParams {

    internal var ownerId: String
    internal var tokenIds: [String]? = nil
    internal var serialNumbers: [String]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .rejectToken
        let params = try JSONRPCParser.getRequiredRequestParams(request: request)

        self.ownerId = try JSONRPCParser.getRequiredParameter(name: "ownerId", from: params, for: method)
        self.tokenIds = try JSONRPCParser.getOptionalPrimitiveListIfPresent(name: "tokenIds", from: params, for: method)
        self.serialNumbers = try JSONRPCParser.getOptionalPrimitiveListIfPresent(name: "serialNumbers", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
