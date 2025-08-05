// SPDX-License-Identifier: Apache-2.0

/// Represents an HBAR transfer parsed from a JSON-RPC request.
///
/// This struct is used to decode and validate a single HBAR transfer entry. It includes:
/// - `accountId`: A Hiero Account ID to receive or send HBAR.
/// - `evmAddress`: An EVM-compatible address for to receiver or send HBAR.
/// - `amount`: The amount of HBAR to transfer, specified as a string to maintain precision.
///
/// One of `accountId` or `evmAddress` must be present to identify the transfer target.
internal struct HbarTransfer {

    internal var accountId: String? = nil
    internal var evmAddress: String? = nil
    internal var amount: String

    internal init(from params: [String: JSONObject], for funcName: JSONRPCMethod) throws {
        self.accountId = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "accountId", from: params, for: funcName)
        self.evmAddress = try JSONRPCParser.getOptionalJsonParameterIfPresent(
            name: "evmAddress", from: params, for: funcName)
        self.amount = try JSONRPCParser.getRequiredJsonParameter(name: "amount", from: params, for: funcName)
    }
}
