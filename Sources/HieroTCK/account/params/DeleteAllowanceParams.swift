// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `deleteAllowance` JSON-RPC method call.
///
/// This struct parses and holds a list of `Allowance` objects to be deleted,
/// which should only be of the `NftAllowance` type. Also parses optional
/// `CommonTransactionParams` for the transaction.
internal struct DeleteAllowanceParams {

    internal var allowances: [RemoveAllowance]
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .deleteAllowance
        let params = try JSONRPCParser.getRequiredRequestParams(request: request)

        self.allowances = try JSONRPCParser.getRequiredCustomObjectList(
            name: "allowances", from: params, for: method, decoder: RemoveAllowance.jsonObjectDecoder(for: method))
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams", from: params, for: method, using: CommonTransactionParams.init)
    }
}
