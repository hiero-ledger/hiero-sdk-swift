// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `approveAllowance` JSON-RPC method call.
///
/// This struct parses and holds a list of `Allowance` objects to be approved,
/// along with optional `CommonTransactionParams` for the transaction.
internal struct ApproveAllowanceParams {

    internal var allowances: [Allowance]
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .approveAllowance
        let params = try JSONRPCParser.getRequiredRequestParams(request: request)

        self.allowances = try JSONRPCParser.getRequiredCustomObjectList(
            name: "allowances", from: params, for: method, decoder: Allowance.jsonObjectDecoder(for: method))
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams", from: params, for: method, using: CommonTransactionParams.init)
    }
}
