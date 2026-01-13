// SPDX-License-Identifier: Apache-2.0

internal struct UpdateContractParams {

    internal var contractId: String? = nil
    internal var adminKey: String? = nil
    internal var autoRenewPeriod: String? = nil
    internal var expirationTime: String? = nil
    internal var memo: String? = nil
    internal var autoRenewAccountId: String? = nil
    internal var maxAutomaticTokenAssociations: Int32? = nil
    internal var stakedAccountId: String? = nil
    internal var stakedNodeId: String? = nil
    internal var declineStakingReward: Bool? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .updateContract
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.contractId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "contractId", from: params, for: method)
        self.adminKey = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "adminKey", from: params, for: method)
        self.autoRenewPeriod = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "autoRenewPeriod", from: params, for: method)
        self.expirationTime = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "expirationTime", from: params, for: method)
        self.memo = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "memo", from: params, for: method)
        self.autoRenewAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "autoRenewAccountId", from: params, for: method)
        self.maxAutomaticTokenAssociations = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "maxAutomaticTokenAssociations", from: params, for: method)
        self.stakedAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "stakedAccountId", from: params, for: method)
        self.stakedNodeId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "stakedNodeId", from: params, for: method)
        self.declineStakingReward = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "declineStakingReward", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
