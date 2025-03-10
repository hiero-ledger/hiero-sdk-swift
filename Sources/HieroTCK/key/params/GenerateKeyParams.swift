// SPDX-License-Identifier: Apache-2.0

/// Struct to hold the parameters of a 'generateKey' JSON-RPC method call.
internal struct GenerateKeyParams {

    internal var type: String
    internal var fromKey: String? = nil
    internal var threshold: UInt32? = nil
    internal var keys: [GenerateKeyParams]? = nil

    internal init(_ request: JSONRequest) throws {
        try self.init(getRequiredParams(request))
    }

    private init(_ params: [String: JSONObject]) throws {
        self.type = try getRequiredJsonParameter("type", params, JSONRPCMethod.generateKey)
        self.fromKey = try getOptionalJsonParameter("fromKey", params, JSONRPCMethod.generateKey)
        self.threshold = try getOptionalJsonParameter("threshold", params, JSONRPCMethod.generateKey)
        self.keys = try (getOptionalJsonParameter("keys", params, JSONRPCMethod.generateKey) as [JSONObject]?)?.map {
            try GenerateKeyParams(getJson($0, "key in keys list", JSONRPCMethod.generateKey) as [String: JSONObject])
        }
    }
}
