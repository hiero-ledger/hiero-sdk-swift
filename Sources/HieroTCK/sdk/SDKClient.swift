// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Manages the Hiero `Client` instance and supports lifecycle operations via JSON-RPC.
///
/// `SDKClient` acts as a singleton controller for the Hiero client used throughout the server.
/// It provides methods to initialize (via `setup`) and reset (via `reset`) the network connection,
/// supporting both testnet and custom configurations.
///
/// Access the singleton instance via `SDKClient.client`.
internal class SDKClient {

    // MARK: - Singleton

    /// Singleton instance of SDKClient.
    static let client = SDKClient()

    // MARK: - JSON-RPC Methods

    /// Handles the `reset` JSON-RPC method.
    internal func reset(from params: ResetParams) throws -> JSONObject {
        self.client = try Client.forNetwork([String: AccountId]())
        return .dictionary(["status": .string("SUCCESS")])
    }

    /// Handles the `setup` JSON-RPC method.
    internal func setup(from params: SetupParams) throws -> JSONObject {
        let operatorAccountId = try AccountId.fromString(params.operatorAccountId)
        let operatorPrivateKey = try PrivateKey.fromStringDer(params.operatorPrivateKey)

        let clientType: String
        if params.nodeIp == nil, params.nodeAccountId == nil, params.mirrorNetworkIp == nil {
            self.client = Client.forTestnet()
            clientType = "testnet"
        } else if let nodeIp = params.nodeIp,
            let nodeAccountId = params.nodeAccountId,
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

        return .dictionary([
            "message": .string("Successfully setup \(clientType) client."),
            "success": .string("SUCCESS"),
        ])

    }

    // MARK: - Helpers

    /// Returns the active `Hiero.Client` instance.
    internal func getClient() -> Client {
        return client
    }

    // MARK: - Private

    /// Initializes with a default testnet client.
    /// This placeholder is meant to be overwritten via the `setup` JSON-RPC method.
    fileprivate init() {
        self.client = Client.forTestnet()
    }

    /// Internal client instance wrapped by this class.
    private var client: Client
}
