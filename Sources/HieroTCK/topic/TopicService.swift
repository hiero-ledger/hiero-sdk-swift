// SPDX-License-Identifier: Apache-2.0

import Foundation

@testable import Hiero

/// Service responsible for handling topic-related JSON-RPC methods.
///
/// Each method corresponds to a specific JSON-RPC operation, maps input parameters into
/// Hiero SDK requests, and returns a structured result.
internal enum TopicService {

    // MARK: - JSON-RPC Methods

    /// Handles the `createTopic` JSON-RPC method.
    internal static func createTopic(from params: CreateTopicParams) async throws -> JSONObject {
        var tx = TopicCreateTransaction()
        let method: JSONRPCMethod = .createTopic

        params.memo.assign(to: &tx.topicMemo)
        tx.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tx.submitKey = try CommonParamsParser.getKeyIfPresent(from: params.submitKey)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(from: params.autoRenewPeriod, for: method)
        tx.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.autoRenewAccountId)
        tx.feeScheduleKey = try CommonParamsParser.getKeyIfPresent(from: params.feeScheduleKey)
        try params.feeExemptKeys.assign(to: &tx.feeExemptKeys) { try $0.map { try KeyService.getHieroKey(from: $0) } }
        try CommonParamsParser.getHieroCustomFixedFeesIfPresent(from: params.customFees, for: method)
            .assign(to: &tx.customFees)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "topicId": .string(txReceipt.topicId!.toString()),
            "status": .string(txReceipt.status.description),
        ])
    }

    /// Handles the `deleteTopic` JSON-RPC method.
    internal static func deleteTopic(from params: DeleteTopicParams) async throws -> JSONObject {
        var tx = TopicDeleteTransaction()

        tx.topicId = try CommonParamsParser.getTopicIdIfPresent(from: params.topicId)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateTopic` JSON-RPC method.
    internal static func updateTopic(from params: UpdateTopicParams) async throws -> JSONObject {
        var tx = TopicUpdateTransaction()
        let method: JSONRPCMethod = .updateTopic

        tx.topicId = try CommonParamsParser.getTopicIdIfPresent(from: params.topicId)
        params.memo.assign(to: &tx.topicMemo)
        tx.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tx.submitKey = try CommonParamsParser.getKeyIfPresent(from: params.submitKey)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(from: params.autoRenewPeriod, for: method)
        tx.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.autoRenewAccountId)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(from: params.expirationTime, for: method)
        tx.feeScheduleKey = try CommonParamsParser.getKeyIfPresent(from: params.feeScheduleKey)
        tx.feeExemptKeys = try params.feeExemptKeys.map { try $0.map { try KeyService.getHieroKey(from: $0) } }
        tx.customFees = try CommonParamsParser.getHieroCustomFixedFeesIfPresent(from: params.customFees, for: method)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `submitTopicMessage` JSON-RPC method.
    internal static func submitTopicMessage(from params: SubmitTopicMessageParams) async throws -> JSONObject {
        var tx = TopicMessageSubmitTransaction()
        let method: JSONRPCMethod = .submitTopicMessage

        tx.topicId = try CommonParamsParser.getTopicIdIfPresent(from: params.topicId)
        params.message.assign(to: &tx.message) { Data($0.utf8) }
        params.maxChunks.assign(to: &tx.maxChunks) { Int($0) }
        params.chunkSize.assign(to: &tx.chunkSize) { Int($0) }
        try params.customFeeLimits.assign(to: &tx.customFeeLimits) { try $0.map { try $0.toHiero(for: method) } }
        try params.commonTransactionParams?.applyToTransaction(&tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "status": .string(txReceipt.status.description),
        ])
    }
}
