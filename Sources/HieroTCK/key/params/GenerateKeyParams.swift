/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

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
