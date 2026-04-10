// SPDX-License-Identifier: Apache-2.0

import Hiero

/// Service responsible for handling file-related JSON-RPC methods.
///
/// Each method corresponds to a specific JSON-RPC operation, maps input parameters into
/// Hiero SDK requests, and returns a structured result.
internal enum FileService {

    // MARK: - JSON-RPC Methods

    /// Handles the `appendFile` JSON-RPC method.
    internal static func appendFile(from params: AppendFileParams) async throws -> JSONObject {
        var tx = FileAppendTransaction()

        tx.fileId = try CommonParamsParser.getFileIdIfPresent(from: params.fileId)
        try CommonParamsParser.getContentsIfPresent(from: params.contents, for: .appendFile).assignIfPresent(
            to: &tx.contents)
        params.maxChunks.assignIfPresent(to: &tx.maxChunks)
        params.chunkSize.assignIfPresent(to: &tx.chunkSize)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `createFile` JSON-RPC method.
    internal static func createFile(from params: CreateFileParams) async throws -> JSONObject {
        var tx = FileCreateTransaction()
        let method: JSONRPCMethod = .createFile

        try CommonParamsParser.getKeyListIfPresent(from: params.keys).assignIfPresent(to: &tx.keys)
        try CommonParamsParser.getContentsIfPresent(from: params.contents, for: method).assignIfPresent(
            to: &tx.contents)
        try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method).assignIfPresent(
            to: &tx.expirationTime)
        params.memo.assignIfPresent(to: &tx.fileMemo)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "fileId": .string(txReceipt.fileId!.toString()),
            "status": .string(txReceipt.status.description),
        ])
    }

    /// Handles the `deleteFile` JSON-RPC method.
    internal static func deleteFile(from params: DeleteFileParams) async throws -> JSONObject {
        var tx = FileDeleteTransaction()

        tx.fileId = try CommonParamsParser.getFileIdIfPresent(from: params.fileId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateFile` JSON-RPC method.
    internal static func updateFile(from params: UpdateFileParams) async throws -> JSONObject {
        var tx = FileUpdateTransaction()
        let method: JSONRPCMethod = .updateFile

        tx.fileId = try CommonParamsParser.getFileIdIfPresent(from: params.fileId)
        tx.keys = try CommonParamsParser.getKeyListIfPresent(from: params.keys)
        try CommonParamsParser.getContentsIfPresent(from: params.contents, for: method).assignIfPresent(
            to: &tx.contents)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method)
        params.memo.assignIfPresent(to: &tx.fileMemo)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }
}
