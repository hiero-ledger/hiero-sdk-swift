// SPDX-License-Identifier: Apache-2.0

internal struct ContractCallQueryParams {

    internal var contractId: String?
    internal var gas: String?
    internal var functionName: String?
    internal var functionParameters: String?
    internal var maxQueryPayment: String?
    internal var senderAccountId: String?

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .contractCallQuery
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.contractId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "contractId", from: params, for: method)
        self.gas = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "gas", from: params, for: method)
        self.functionName = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "functionName", from: params, for: method)
        self.functionParameters = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "functionParameters", from: params, for: method)
        self.maxQueryPayment = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "maxQueryPayment", from: params, for: method)
        self.senderAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "senderAccountId", from: params, for: method)
    }
}
