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
    internal func reset(from params: ResetParams) async throws -> JSONObject {
        self.client = try Client.forNetwork([String: AccountId]())
        await self.client.setNetworkUpdatePeriod(nanoseconds: nil)
        return .dictionary(["status": .string("SUCCESS")])
    }

    /// Handles the `setOperator` JSON-RPC method.
    ///
    /// Updates the operator (payer) on the existing client without recreating it.
    internal func setOperator(from params: SetOperatorParams) throws -> JSONObject {
        let operatorAccountId = try AccountId.fromString(params.operatorAccountId)
        let operatorPrivateKey = try PrivateKey.fromStringDer(params.operatorPrivateKey)
        
        self.client.setOperator(operatorAccountId, operatorPrivateKey)
        return .dictionary(["status": .string("SUCCESS")])
    }

    /// Handles the `setup` JSON-RPC method.
    internal func setup(from params: SetupParams) async throws -> JSONObject {
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

        // Disable automatic network updates
        await self.client.setNetworkUpdatePeriod(nanoseconds: nil)

        return .dictionary([
            "message": .string("Successfully setup \(clientType) client."),
            "success": .string("SUCCESS"),
        ])

    }

    // MARK: - Helpers

    /// Executes a Hiero transaction and wraps its final status in a JSON-RPC friendly `JSONObject`.
    ///
    /// This is a convenience for JSON-RPC responses where only the transaction status is required,
    /// rather than the full receipt. The status is returned as a `.dictionary` containing a single
    /// `"status"` key with the string description of the receipt status.
    ///
    /// - Parameters:
    ///   - tx: The Hiero transaction to execute.
    /// - Returns: A `JSONObject.dictionary` with `"status"` mapped to the transaction's final status string.
    /// - Throws: Any error that occurs while executing the transaction or fetching its receipt.
    internal func executeTransactionAndGetJsonRpcStatus<T: Transaction>(_ tx: T) async throws -> JSONObject {
        let txReceipt = try await executeTransactionAndGetReceipt(tx)
        return .dictionary(["status": .string(txReceipt.status.description)])
    }

    /// Executes a Hiero transaction and waits for its final receipt.
    ///
    /// This submits the transaction to the Hiero network, waits for consensus, and then queries
    /// the network for the transaction's receipt. The receipt contains the authoritative final
    /// outcome of the transaction (e.g. status, new entity IDs, etc.).
    ///
    /// - Parameters:
    ///   - tx: The Hiero transaction to execute.
    /// - Returns: The `TransactionReceipt` for the transaction once consensus is reached.
    /// - Throws: Any error that occurs during execution or receipt retrieval.
    internal func executeTransactionAndGetReceipt<T: Transaction>(_ tx: T) async throws
        -> TransactionReceipt
    {
        return try await tx.execute(client).getReceipt(client)
    }

    /// Freezes a Hiero transaction with the current client.
    ///
    /// Freezing finalizes the transaction body, preventing further modifications to its fields
    /// and preparing it for signing and execution. This is a required step before submitting
    /// a transaction to the network.
    ///
    /// - Parameters:
    ///   - tx: The transaction to freeze. Passed `inout` so its state is updated in place.
    /// - Throws: Any error encountered while freezing the transaction (e.g. invalid configuration).
    internal func freezeTransaction<T: Transaction>(_ tx: inout T) throws {
        try tx.freezeWith(client)
    }

    // MARK: - Private

    /// Initializes with a placeholder empty client.
    ///
    /// This is meant to be overwritten via the `setup` JSON-RPC method.
    private init() {
        // Create an empty client - will be replaced by setup()
        self.client = try! Client.forNetwork([String: AccountId]())
    }

    /// Internal client instance wrapped by this class.
    private var client: Client
}
