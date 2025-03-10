// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'updateAccount' JSON-RPC method call.
internal struct UpdateAccountParams {

    internal var accountId: String? = nil
    internal var key: String? = nil
    internal var autoRenewPeriod: String? = nil
    internal var expirationTime: String? = nil
    internal var receiverSignatureRequired: Bool? = nil
    internal var memo: String? = nil
    internal var maxAutoTokenAssociations: Int32? = nil
    internal var stakedAccountId: String? = nil
    internal var stakedNodeId: String? = nil
    internal var declineStakingReward: Bool? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.accountId = try getOptionalJsonParameter("accountId", params, JSONRPCMethod.updateAccount)
            self.key = try getOptionalJsonParameter("key", params, JSONRPCMethod.updateAccount)
            self.autoRenewPeriod = try getOptionalJsonParameter("autoRenewPeriod", params, JSONRPCMethod.updateAccount)
            self.expirationTime = try getOptionalJsonParameter("expirationTime", params, JSONRPCMethod.updateAccount)
            self.receiverSignatureRequired = try getOptionalJsonParameter(
                "receiverSignatureRequired", params, JSONRPCMethod.updateAccount)
            self.memo = try getOptionalJsonParameter("memo", params, JSONRPCMethod.updateAccount)
            self.maxAutoTokenAssociations = try getOptionalJsonParameter(
                "maxAutoTokenAssociations", params, JSONRPCMethod.updateAccount)
            self.stakedAccountId = try getOptionalJsonParameter("stakedAccountId", params, JSONRPCMethod.updateAccount)
            self.stakedNodeId = try getOptionalJsonParameter("stakedNodeId", params, JSONRPCMethod.updateAccount)
            self.declineStakingReward = try getOptionalJsonParameter(
                "declineStakingReward", params, JSONRPCMethod.updateAccount)
            self.commonTransactionParams = try CommonTransactionParams(
                getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.updateAccount),
                JSONRPCMethod.updateAccount)
        }
    }
}
