// SPDX-License-Identifier: Apache-2.0

internal struct UpdateContractParams {

    internal var contractId: String?
    internal var adminKey: String?
    internal var autoRenewPeriod: String?
    internal var expirationTime: String?
    internal var memo: String?
    internal var autoRenewAccountId: String?
    internal var maxAutomaticTokenAssociations: Int32?
    internal var stakedAccountId: String?
    internal var stakedNodeId: String?
    internal var declineStakingReward: Bool?
    internal var commonTransactionParams: CommonTransactionParams?

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
