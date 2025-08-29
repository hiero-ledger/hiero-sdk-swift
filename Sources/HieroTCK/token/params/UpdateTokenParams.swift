// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for an `updateToken` JSON-RPC method call.
///
/// This struct captures all optional fields that can be updated for a Hiero token,
/// including metadata, cryptographic keys, treasury configuration, and lifecycle settings.
/// The fields are parsed from a JSON-RPC request and individually validated.
///
/// - Note: All fields are optional; validation and defaulting behavior should be handled downstream.
internal struct UpdateTokenParams {

    // MARK: - Properties

    internal var tokenId: String? = nil
    internal var symbol: String? = nil
    internal var name: String? = nil
    internal var treasuryAccountId: String? = nil
    internal var adminKey: String? = nil
    internal var kycKey: String? = nil
    internal var freezeKey: String? = nil
    internal var wipeKey: String? = nil
    internal var supplyKey: String? = nil
    internal var autoRenewAccountId: String? = nil
    internal var autoRenewPeriod: String? = nil
    internal var expirationTime: String? = nil
    internal var memo: String? = nil
    internal var feeScheduleKey: String? = nil
    internal var pauseKey: String? = nil
    internal var metadata: String? = nil
    internal var metadataKey: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    // MARK: - Initializers

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .updateTokenFeeSchedule
        guard let params = try JSONRPCParser.getOptionalRequestParamsIfPresent(request: request) else { return }

        self.tokenId = try JSONRPCParser.getOptionalParameterIfPresent(name: "tokenId", from: params, for: method)
        self.symbol = try JSONRPCParser.getOptionalParameterIfPresent(name: "symbol", from: params, for: method)
        self.name = try JSONRPCParser.getOptionalParameterIfPresent(name: "name", from: params, for: method)
        self.treasuryAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "treasuryAccountId",
            from: params,
            for: method)
        self.adminKey = try JSONRPCParser.getOptionalParameterIfPresent(name: "adminKey", from: params, for: method)
        self.kycKey = try JSONRPCParser.getOptionalParameterIfPresent(name: "kycKey", from: params, for: method)
        self.freezeKey = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "freezeKey",
            from: params,
            for: method)
        self.wipeKey = try JSONRPCParser.getOptionalParameterIfPresent(name: "wipeKey", from: params, for: method)
        self.supplyKey = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "supplyKey",
            from: params,
            for: method)
        self.autoRenewAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "autoRenewAccountId",
            from: params,
            for: method)
        self.autoRenewPeriod = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "autoRenewPeriod",
            from: params,
            for: method)
        self.expirationTime = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "expirationTime",
            from: params,
            for: method)
        self.memo = try JSONRPCParser.getOptionalParameterIfPresent(name: "memo", from: params, for: method)
        self.feeScheduleKey = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "feeScheduleKey",
            from: params,
            for: method)
        self.pauseKey = try JSONRPCParser.getOptionalParameterIfPresent(name: "pauseKey", from: params, for: method)
        self.metadata = try JSONRPCParser.getOptionalParameterIfPresent(name: "metadata", from: params, for: method)
        self.metadataKey = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "metadataKey",
            from: params,
            for: method)
        self.commonTransactionParams = try JSONRPCParser.getOptionalCustomObjectIfPresent(
            name: "commonTransactionParams",
            from: params,
            for: method,
            using: CommonTransactionParams.init)
    }
}
