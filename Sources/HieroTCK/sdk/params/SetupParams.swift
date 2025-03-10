// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'setup' JSON-RPC method call.
internal struct SetupParams {

    internal var operatorAccountId: String
    internal var operatorPrivateKey: String
    internal var nodeIp: String? = nil
    internal var nodeAccountId: String? = nil
    internal var mirrorNetworkIp: String? = nil

    internal init(_ request: JSONRequest) throws {
        let params = try getRequiredParams(request)

        self.operatorAccountId = try getRequiredJsonParameter("operatorAccountId", params, JSONRPCMethod.setup)
        self.operatorPrivateKey = try getRequiredJsonParameter("operatorPrivateKey", params, JSONRPCMethod.setup)
        self.nodeIp = try getOptionalJsonParameter("nodeIp", params, JSONRPCMethod.setup)
        self.nodeAccountId = try getOptionalJsonParameter("nodeAccountId", params, JSONRPCMethod.setup)
        self.mirrorNetworkIp = try getOptionalJsonParameter("mirrorNetworkIp", params, JSONRPCMethod.setup)
    }
}
