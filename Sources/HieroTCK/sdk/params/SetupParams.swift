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
