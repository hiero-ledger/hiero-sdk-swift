// SPDX-License-Identifier: Apache-2.0

internal struct ExecuteContractParams {

    internal var contractId: String?
    internal var gas: String?
    internal var amount: String?
    internal var functionParameters: String?
    internal var commonTransactionParams: CommonTransactionParams?

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .executeContract
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.contractId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "contractId", from: params, for: method)
        self.gas = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "gas", from: params, for: method)
        self.amount = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "amount", from: params, for: method)
        self.functionParameters = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "functionParameters", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
