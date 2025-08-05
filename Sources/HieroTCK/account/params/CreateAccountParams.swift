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
        guard let params = try JSONRPCParser.getOptionalParamsIfPresent(request: request) else { return }

        self.key = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "key", from: params, for: method)
        self.initialBalance = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "initialBalance", from: params, for: method)
        self.receiverSignatureRequired = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "receiverSignatureRequired", from: params, for: method)
        self.autoRenewPeriod = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "autoRenewPeriod", from: params, for: method)
        self.memo = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "memo", from: params, for: method)
        self.maxAutoTokenAssociations = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "maxAutoTokenAssociations", from: params, for: method)
        self.stakedAccountId = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "stakedAccountId", from: params, for: method)
        self.stakedNodeId = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "stakedNodeId", from: params, for: method)
        self.declineStakingReward = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "declineStakingReward", from: params, for: method)
        self.alias = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "alias", from: params, for: method)
        self.commonTransactionParams = try CommonTransactionParams(
            from: JSONRPCParser.getOptionalJsonParameterIfPresent(
                name: "commonTransactionParams", from: params, for: method),
            for: method)
    }
}
