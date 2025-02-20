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
import Hiero

/// Client class that handles the connection to the network.
internal class SDKClient {

    /// Singleton instance of SDKClient.
    static let client = SDKClient()

    ////////////////
    /// INTERNAL ///
    ////////////////

    internal init() {
        /// Initialize to testnet to make compiler happy, should be set via `setup` JSON-RPC call.
        self.client = Client.forTestnet()
    }

    /// Get the Hedera Client wrapped by this SDKClient.
    internal func getClient() -> Client {
        return client
    }

    /// Reset the client network. Can be called via JSON-RPC.
    internal func reset(_ params: ResetParams) throws -> JSONObject {
        self.client = try Client.forNetwork([String: AccountId]())
        return JSONObject.dictionary(["status": JSONObject.string("SUCCESS")])
    }

    /// Setup the client network. Can be called via JSON-RPC.
    internal func setup(_ params: SetupParams) throws -> JSONObject {
        let operatorAccountId = try AccountId.fromString(params.operatorAccountId)
        let operatorPrivateKey = try PrivateKey.fromStringDer(params.operatorPrivateKey)

        let clientType: String
        if params.nodeIp == nil, params.nodeAccountId == nil, params.mirrorNetworkIp == nil {
            self.client = Client.forTestnet()
            clientType = "testnet"
        } else if let nodeIp = params.nodeIp, let nodeAccountId = params.nodeAccountId,
            let mirrorNetworkIp = params.mirrorNetworkIp
        {
            self.client = try Client.forNetwork([nodeIp: AccountId.fromString(nodeAccountId)])
            self.client.setMirrorNetwork([mirrorNetworkIp])
            clientType = "custom"
        } else {
            throw JSONError.invalidParams(
                "\(#function): custom network parameters (nodeIp, nodeAccountId, mirrorNetworkIp) SHALL or SHALL NOT all be provided."
            )
        }

        self.client.setOperator(operatorAccountId, operatorPrivateKey)

        return JSONObject.dictionary([
            "message": JSONObject.string("Successfully setup " + clientType + " client."),
            "success": JSONObject.string("SUCCESS"),
        ])

    }

    ///////////////
    /// PRIVATE ///
    ///////////////

    private var client: Client
}
