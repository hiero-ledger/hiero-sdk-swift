// SPDX-License-Identifier: Apache-2.0

/// Represents the parameters for the `setup` JSON-RPC method.
///
/// This struct encapsulates both required and optional fields necessary to configure
/// the Hiero client environment via the `setup` RPC call.
///
/// Required fields:
/// - `operatorAccountId`: The account ID to use as the operator (payer).
/// - `operatorPrivateKey`: The corresponding private key for the operator.
///
/// Optional fields:
/// - `nodeIp`: The IP address of the target Hiero node.
/// - `nodeAccountId`: The account ID of the Hiero node.
/// - `mirrorNetworkIp`: The IP address of the mirror node for query access.
///
/// Validation and parsing is enforced during initialization from a `JSONRequest`.
internal struct SetupParams {

    internal var operatorAccountId: String
    internal var operatorPrivateKey: String
    internal var nodeIp: String? = nil
    internal var nodeAccountId: String? = nil
    internal var mirrorNetworkIp: String? = nil

    internal init(request: JSONRequest) throws {
        let method: JSONRPCMethod = .setup
        let params = try JSONRPCParser.getRequiredRequestParams(request: request)

        self.operatorAccountId = try JSONRPCParser.getRequiredParameter(
            name: "operatorAccountId",
            from: params,
            for: method)
        self.operatorPrivateKey = try JSONRPCParser.getRequiredParameter(
            name: "operatorPrivateKey",
            from: params,
            for: method)
        self.nodeIp = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "nodeIp",
            from: params,
            for: method)
        self.nodeAccountId = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "nodeAccountId",
            from: params,
            for: method)
        self.mirrorNetworkIp = try JSONRPCParser.getOptionalParameterIfPresent(
            name: "mirrorNetworkIp",
            from: params,
            for: method)
    }
}
