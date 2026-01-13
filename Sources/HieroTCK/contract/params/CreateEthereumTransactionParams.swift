// SPDX-License-Identifier: Apache-2.0

internal struct CreateEthereumTransactionParams {

    internal var ethereumData: String? = nil
    internal var callDataFileId: String? = nil
    internal var maxGasAllowance: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .createEthereumTransaction
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.ethereumData = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "ethereumData", from: params, for: method)
        self.callDataFileId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "callDataFileId", from: params, for: method)
        self.maxGasAllowance = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "maxGasAllowance", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
