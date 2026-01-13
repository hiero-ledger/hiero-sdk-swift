// SPDX-License-Identifier: Apache-2.0

internal struct CreateContractParams {

    internal var bytecodeFileId: String?
    internal var adminKey: String?
    internal var gas: String?
    internal var initialBalance: String?
    internal var constructorParameters: String?
    internal var autoRenewPeriod: String?
    internal var autoRenewAccountId: String?
    internal var memo: String?
    internal var stakedAccountId: String?
    internal var stakedNodeId: String?
    internal var declineStakingReward: Bool?
    internal var maxAutomaticTokenAssociations: Int32?
    internal var initcode: String?
    internal var commonTransactionParams: CommonTransactionParams?

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .createContract
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.bytecodeFileId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "bytecodeFileId", from: params, for: method)
        self.adminKey = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "adminKey", from: params, for: method)
        self.gas = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "gas", from: params, for: method)
        self.initialBalance = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "initialBalance", from: params, for: method)
        self.constructorParameters = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "constructorParameters", from: params, for: method)
        self.autoRenewPeriod = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "autoRenewPeriod", from: params, for: method)
        self.autoRenewAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "autoRenewAccountId", from: params, for: method)
        self.memo = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "memo", from: params, for: method)
        self.stakedAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "stakedAccountId", from: params, for: method)
        self.stakedNodeId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "stakedNodeId", from: params, for: method)
        self.declineStakingReward = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "declineStakingReward", from: params, for: method)
        self.maxAutomaticTokenAssociations = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "maxAutomaticTokenAssociations", from: params, for: method)
        self.initcode = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "initcode", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
