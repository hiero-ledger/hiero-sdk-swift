// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for a `createToken` JSON-RPC method call.
///
/// This struct captures all supported token creation parameters,
/// including identity, supply configuration, keys, metadata, and fee schedule.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct CreateTokenParams {

    internal var name: String? = nil
    internal var symbol: String? = nil
    internal var decimals: UInt32? = nil
    internal var initialSupply: String? = nil
    internal var treasuryAccountId: String? = nil
    internal var adminKey: String? = nil
    internal var kycKey: String? = nil
    internal var freezeKey: String? = nil
    internal var wipeKey: String? = nil
    internal var supplyKey: String? = nil
    internal var freezeDefault: Bool? = nil
    internal var expirationTime: String? = nil
    internal var autoRenewAccountId: String? = nil
    internal var autoRenewPeriod: String? = nil
    internal var memo: String? = nil
    internal var tokenType: String? = nil
    internal var supplyType: String? = nil
    internal var maxSupply: String? = nil
    internal var feeScheduleKey: String? = nil
    internal var customFees: [CustomFee]? = nil
    internal var pauseKey: String? = nil
    internal var metadata: String? = nil
    internal var metadataKey: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .createAccount
        guard let params = try JSONRPCParser.getOptionalParamsIfPresent(request: request) else { return }

        self.name = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "name", from: params, for: method)
        self.symbol = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "symbol", from: params, for: method)
        self.decimals = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "decimals", from: params, for: method)
        self.initialSupply = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "initialSupply", from: params, for: method)
        self.treasuryAccountId = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "treasuryAccountId", from: params, for: method)
        self.adminKey = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "adminKey", from: params, for: method)
        self.kycKey = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "kycKey", from: params, for: method)
        self.freezeKey = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "freezeKey", from: params, for: method)
        self.wipeKey = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "wipeKey", from: params, for: method)
        self.supplyKey = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "supplyKey", from: params, for: method)
        self.freezeDefault = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "freezeDefault", from: params, for: method)
        self.expirationTime = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "expirationTime", from: params, for: method)
        self.autoRenewAccountId = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "autoRenewAccountId", from: params, for: method)
        self.autoRenewPeriod = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "autoRenewPeriod", from: params, for: method)
        self.memo = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "memo", from: params, for: method)
        self.tokenType = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "tokenType", from: params, for: method)
        self.supplyType = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "supplyType", from: params, for: method)
        self.maxSupply = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "maxSupply", from: params, for: method)
        self.feeScheduleKey = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "feeScheduleKey", from: params, for: method)
        self.customFees = try JSONRPCParser.getOptionalCustomObjectListIfPresent(
            name: "customFees", from: params, for: method, decoder: CustomFee.jsonObjectDecoder(for: method))
        self.pauseKey = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "pauseKey", from: params, for: method)
        self.metadata = try JSONRPCParser.getOptionalJsonParameterIfPresent(name: "metadata", from: params, for: method)
        self.metadataKey = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "metadataKey", from: params, for: method)
        self.commonTransactionParams = try CommonTransactionParams(
            from: try JSONRPCParser.getOptionalJsonParameterIfPresent(
                name: "commonTransactionParams", from: params, for: method),
            for: method)
    }
}
