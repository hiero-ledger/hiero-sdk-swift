// SPDX-License-Identifier: Apache-2.0

internal struct ContractByteCodeQueryParams {

    internal var contractId: String?
    internal var queryPayment: String?
    internal var maxQueryPayment: String?

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .contractByteCodeQuery
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.contractId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "contractId", from: params, for: method)
        self.queryPayment = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "queryPayment", from: params, for: method)
        self.maxQueryPayment = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "maxQueryPayment", from: params, for: method)
    }
}
