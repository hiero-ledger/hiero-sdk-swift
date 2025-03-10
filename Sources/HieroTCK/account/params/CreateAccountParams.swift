// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'createAccount' JSON-RPC method call.
internal struct CreateAccountParams {

    internal var key: String? = nil
    internal var initialBalance: String? = nil
    internal var receiverSignatureRequired: Bool? = nil
    internal var autoRenewPeriod: String? = nil
    internal var memo: String? = nil
    internal var maxAutoTokenAssociations: Int32? = nil
    internal var stakedAccountId: String? = nil
    internal var stakedNodeId: String? = nil
    internal var declineStakingReward: Bool? = nil
    internal var alias: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.key = try getOptionalJsonParameter("key", params, JSONRPCMethod.createAccount)
            self.initialBalance = try getOptionalJsonParameter("initialBalance", params, JSONRPCMethod.createAccount)
            self.receiverSignatureRequired = try getOptionalJsonParameter(
                "receiverSignatureRequired", params, JSONRPCMethod.createAccount)
            self.autoRenewPeriod = try getOptionalJsonParameter("autoRenewPeriod", params, JSONRPCMethod.createAccount)
            self.memo = try getOptionalJsonParameter("memo", params, JSONRPCMethod.createAccount)
            self.maxAutoTokenAssociations = try getOptionalJsonParameter(
                "maxAutoTokenAssociations", params, JSONRPCMethod.createAccount)
            self.stakedAccountId = try getOptionalJsonParameter("stakedAccountId", params, JSONRPCMethod.createAccount)
            self.stakedNodeId = try getOptionalJsonParameter("stakedNodeId", params, JSONRPCMethod.createAccount)
            self.declineStakingReward = try getOptionalJsonParameter(
                "declineStakingReward", params, JSONRPCMethod.createAccount)
            self.alias = try getOptionalJsonParameter("alias", params, JSONRPCMethod.createAccount)
            self.commonTransactionParams = try CommonTransactionParams(
                getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.createAccount),
                JSONRPCMethod.createAccount)
        }
    }
}
