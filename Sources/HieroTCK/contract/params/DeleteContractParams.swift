// SPDX-License-Identifier: Apache-2.0

internal struct DeleteContractParams {

    internal var contractId: String? = nil
    internal var transferAccountId: String? = nil
    internal var transferContractId: String? = nil
    internal var permanentRemoval: Bool? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .deleteContract
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.contractId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "contractId", from: params, for: method)
        self.transferAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "transferAccountId", from: params, for: method)
        self.transferContractId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "transferContractId", from: params, for: method)
        self.permanentRemoval = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "permanentRemoval", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
