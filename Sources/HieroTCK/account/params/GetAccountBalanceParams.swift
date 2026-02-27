// SPDX-License-Identifier: Apache-2.0

/// Parameters for the `getAccountBalance` JSON-RPC method.
internal struct GetAccountBalanceParams {
    internal let method: JSONRPCMethod = .getAccountBalance

    internal var accountId: String?
    internal var contractId: String?

    internal init(request: JSONRequest) throws {
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else {
            return
        }

        self.accountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "accountId",
            from: params,
            for: method
        )
        self.contractId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "contractId",
            from: params,
            for: method
        )
    }
}
