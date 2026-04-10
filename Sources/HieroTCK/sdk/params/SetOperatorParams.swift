// SPDX-License-Identifier: Apache-2.0

/// Represents the JSON-RPC parameters for the `setOperator` method.
///
/// Updates the operator (payer) on an existing client session without recreating the client.
internal struct SetOperatorParams {

    internal var operatorAccountId: String
    internal var operatorPrivateKey: String

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .setOperator
        let params = try JSONRPCParser.getRequiredRequestParams(request: request)

        self.operatorAccountId = try JSONRPCParser.getRequiredParameter(
            name: "operatorAccountId",
            from: params,
            for: method)
        self.operatorPrivateKey = try JSONRPCParser.getRequiredParameter(
            name: "operatorPrivateKey",
            from: params,
            for: method)
    }
}
