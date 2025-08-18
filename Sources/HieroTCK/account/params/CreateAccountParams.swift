// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `createAccount` JSON-RPC method call.
///
/// This struct parses and stores all optional fields supported by the `createAccount` method,
/// including cryptographic keys, staking preferences, auto-renew settings, and transaction metadata.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
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

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .createAccount
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.key = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "key", from: params, for: method)
        self.initialBalance = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "initialBalance", from: params, for: method)
        self.receiverSignatureRequired = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "receiverSignatureRequired", from: params, for: method)
        self.autoRenewPeriod = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "autoRenewPeriod", from: params, for: method)
        self.memo = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "memo", from: params, for: method)
        self.maxAutoTokenAssociations = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "maxAutoTokenAssociations", from: params, for: method)
        self.stakedAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "stakedAccountId", from: params, for: method)
        self.stakedNodeId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "stakedNodeId", from: params, for: method)
        self.declineStakingReward = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "declineStakingReward", from: params, for: method)
        self.alias = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "alias", from: params, for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams", from: params, for: method, using: CommonTransactionParams.init)
    }
}
