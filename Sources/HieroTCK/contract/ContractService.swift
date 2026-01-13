// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

internal enum ContractService {

    /// Handles the `contractCallQuery` JSON-RPC method.
    internal static func contractCallQuery(from params: ContractCallQueryParams) async throws -> JSONObject {
        let query = ContractCallQuery()
        let method: JSONRPCMethod = .contractCallQuery

        query.contractId = try CommonParamsParser.getContractIdIfPresent(from: params.contractId)
        try CommonParamsParser.getGasIfPresent(from: params.gas, for: method).assignIfPresent(to: &query.gas)
        query.functionParameters = try CommonParamsParser.getFunctionParametersIfPresent(
            from: params.functionParameters)
        params.functionName.ifPresent { query.function($0) }
        try CommonParamsParser.getMaxQueryPaymentIfPresent(from: params.maxQueryPayment, for: method)
            .ifPresent { query.maxPaymentAmount($0) }
        query.senderAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.senderAccountId)

        let result = try await SDKClient.client.executeQuery(query)

        var response: [String: JSONObject] = [:]
        response["bytes"] = .string("0x" + result.bytes.map { String(format: "%02x", $0) }.joined())
        response["contractId"] = .string(result.contractId.toString())
        response["gasUsed"] = .string(String(result.gasUsed))

        if let errorMessage = result.errorMessage, !errorMessage.isEmpty {
            response["errorMessage"] = .string(errorMessage)
        }

        // Extract return value types at index 0
        result.getString(0).ifPresent { response["string"] = .string($0) }
        result.getBool(0).ifPresent { response["bool"] = .bool($0) }
        result.getAddress(0).ifPresent { response["address"] = .string("0x" + $0) }

        if result.bytes.count >= 32 {
            result.getBytes32(0).ifPresent {
                response["bytes32"] = .string("0x" + $0.map { String(format: "%02x", $0) }.joined())
            }
        }

        // Integer types
        result.getInt8(0).ifPresent { response["int8"] = .string(String($0)) }
        result.getUInt8(0).ifPresent { response["uint8"] = .string(String($0)) }
        result.getInt32(0).ifPresent { response["int32"] = .string(String($0)) }
        result.getUInt32(0).ifPresent { response["uint32"] = .string(String($0)) }
        result.getInt64(0).ifPresent { response["int64"] = .string(String($0)) }
        result.getUInt64(0).ifPresent { response["uint64"] = .string(String($0)) }
        result.getInt256(0).ifPresent { response["int256"] = .string(String($0)) }
        result.getUInt256(0).ifPresent { response["uint256"] = .string(String($0)) }

        return .dictionary(response)
    }

    /// Handles the `contractByteCodeQuery` JSON-RPC method.
    internal static func contractByteCodeQuery(from params: ContractByteCodeQueryParams) async throws -> JSONObject {
        let query = ContractBytecodeQuery()
        let method: JSONRPCMethod = .contractByteCodeQuery

        query.contractId = try CommonParamsParser.getContractIdIfPresent(from: params.contractId)
        try CommonParamsParser.getQueryPaymentIfPresent(from: params.queryPayment, for: method)
            .ifPresent { query.paymentAmount($0) }
        try CommonParamsParser.getMaxQueryPaymentIfPresent(from: params.maxQueryPayment, for: method)
            .ifPresent { query.maxPaymentAmount($0) }

        let result = try await SDKClient.client.executeQuery(query)

        var response: [String: JSONObject] = [:]
        if !result.isEmpty {
            response["bytecode"] = .string("0x" + result.map { String(format: "%02x", $0) }.joined())
        }
        query.contractId.ifPresent { response["contractId"] = .string($0.toString()) }

        return .dictionary(response)
    }

    /// Handles the `contractInfoQuery` JSON-RPC method.
    internal static func contractInfoQuery(from params: ContractInfoQueryParams) async throws -> JSONObject {
        let query = ContractInfoQuery()
        let method: JSONRPCMethod = .contractInfoQuery

        query.contractId = try CommonParamsParser.getContractIdIfPresent(from: params.contractId)
        try CommonParamsParser.getQueryPaymentIfPresent(from: params.queryPayment, for: method)
            .ifPresent { query.paymentAmount($0) }
        try CommonParamsParser.getMaxQueryPaymentIfPresent(from: params.maxQueryPayment, for: method)
            .ifPresent { query.maxPaymentAmount($0) }

        let result = try await SDKClient.client.executeQuery(query)

        var response: [String: JSONObject] = [:]

        response["contractId"] = .string(result.contractId.toString())
        response["accountId"] = .string(result.accountId.toString())
        response["contractAccountId"] = .string(result.contractAccountId)

        result.adminKey.ifPresent {
            if case .single(let publicKey) = $0 {
                response["adminKey"] = .string(publicKey.toStringDer())
            }
        }
        result.expirationTime.ifPresent { response["expirationTime"] = .string($0.description) }
        result.autoRenewPeriod.ifPresent { response["autoRenewPeriod"] = .string(String($0.seconds)) }
        result.autoRenewAccountId.ifPresent { response["autoRenewAccountId"] = .string($0.toString()) }

        response["storage"] = .string(String(result.storage))
        response["contractMemo"] = .string(result.contractMemo)
        response["balance"] = .string(String(result.balance.toTinybars()))
        response["isDeleted"] = .bool(result.isDeleted)
        response["maxAutomaticTokenAssociations"] = .string(String(result.maxAutomaticTokenAssociations))
        response["ledgerId"] = .string(result.ledgerId.toString())

        var stakingInfo: [String: JSONObject] = [:]
        stakingInfo["declineStakingReward"] = .bool(result.stakingInfo.declineStakingReward)
        result.stakingInfo.stakePeriodStart.ifPresent { stakingInfo["stakePeriodStart"] = .string($0.description) }
        stakingInfo["pendingReward"] = .string(String(result.stakingInfo.pendingReward.toTinybars()))
        stakingInfo["stakedToMe"] = .string(String(result.stakingInfo.stakedToMe.toTinybars()))
        result.stakingInfo.stakedAccountId.ifPresent { stakingInfo["stakedAccountId"] = .string($0.toString()) }
        result.stakingInfo.stakedNodeId.ifPresent { stakingInfo["stakedNodeId"] = .string(String($0)) }

        response["stakingInfo"] = .dictionary(stakingInfo)

        return .dictionary(response)
    }

    /// Handles the `createContract` JSON-RPC method.
    internal static func createContract(from params: CreateContractParams) async throws -> JSONObject {
        var tx = ContractCreateTransaction()
        let method: JSONRPCMethod = .createContract

        tx.bytecodeFileId = try CommonParamsParser.getFileIdIfPresent(from: params.bytecodeFileId)
        tx.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        try CommonParamsParser.getGasIfPresent(from: params.gas, for: method).assignIfPresent(to: &tx.gas)
        try CommonParamsParser.getInitialBalanceIfPresent(from: params.initialBalance, for: method)
            .assignIfPresent(to: &tx.initialBalance)
        tx.constructorParameters = try CommonParamsParser.parseHexToDataIfPresent(
            from: params.constructorParameters, paramName: "constructorParameters")
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod, for: method)
        tx.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.autoRenewAccountId)
        params.memo.assignIfPresent(to: &tx.contractMemo)
        tx.stakedAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.stakedAccountId)
        tx.stakedNodeId = try CommonParamsParser.getStakedNodeIdIfPresent(from: params.stakedNodeId, for: method)
        params.declineStakingReward.assignIfPresent(to: &tx.declineStakingReward)
        params.maxAutomaticTokenAssociations.assignIfPresent(to: &tx.maxAutomaticTokenAssociations)
        tx.bytecode = try CommonParamsParser.parseHexToDataIfPresent(from: params.initcode, paramName: "initcode")
        try params.commonTransactionParams?.applyToTransaction(&tx)

        let txReceipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)
        return .dictionary([
            "contractId": .string(txReceipt.contractId!.toString()),
            "status": .string(txReceipt.status.description),
        ])
    }

    /// Handles the `createEthereumTransaction` JSON-RPC method.
    internal static func createEthereumTransaction(from params: CreateEthereumTransactionParams) async throws
        -> JSONObject
    {
        var tx = EthereumTransaction()
        let method: JSONRPCMethod = .createEthereumTransaction

        tx.ethereumData = try CommonParamsParser.parseHexToDataIfPresent(
            from: params.ethereumData, paramName: "ethereumData")
        tx.callDataFileId = try CommonParamsParser.getFileIdIfPresent(from: params.callDataFileId)
        try params.maxGasAllowance.assignIfPresent(to: &tx.maxGasAllowanceHbar) {
            Hbar.fromTinybars(try CommonParamsParser.getAmount(from: $0, for: method, using: JSONRPCParam.parseInt64))
        }
        try params.commonTransactionParams?.applyToTransaction(&tx)

        let receipt = try await SDKClient.client.executeTransactionAndGetReceipt(tx)

        var result: [String: JSONObject] = [:]
        result["status"] = .string(receipt.status.description)
        receipt.contractId.ifPresent { result["contractId"] = .string($0.toString()) }

        return .dictionary(result)
    }

    /// Handles the `deleteContract` JSON-RPC method.
    internal static func deleteContract(from params: DeleteContractParams) async throws -> JSONObject {
        var tx = ContractDeleteTransaction()

        tx.contractId = try CommonParamsParser.getContractIdIfPresent(from: params.contractId)
        tx.transferAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.transferAccountId)
        tx.transferContractId = try CommonParamsParser.getContractIdIfPresent(from: params.transferContractId)
        params.permanentRemoval.assignIfPresent(to: &tx.permanentRemoval)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `executeContract` JSON-RPC method.
    internal static func executeContract(from params: ExecuteContractParams) async throws -> JSONObject {
        var tx = ContractExecuteTransaction()
        let method: JSONRPCMethod = .executeContract

        tx.contractId = try CommonParamsParser.getContractIdIfPresent(from: params.contractId)
        try CommonParamsParser.getGasIfPresent(from: params.gas, for: method).assignIfPresent(to: &tx.gas)
        try params.amount.assignIfPresent(to: &tx.payableAmount) {
            Hbar.fromTinybars(try CommonParamsParser.getAmount(from: $0, for: method, using: JSONRPCParam.parseInt64))
        }
        tx.functionParameters = try CommonParamsParser.getFunctionParametersIfPresent(from: params.functionParameters)
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }

    /// Handles the `updateContract` JSON-RPC method.
    internal static func updateContract(from params: UpdateContractParams) async throws -> JSONObject {
        var tx = ContractUpdateTransaction()
        let method: JSONRPCMethod = .updateContract

        tx.contractId = try CommonParamsParser.getContractIdIfPresent(from: params.contractId)
        tx.adminKey = try CommonParamsParser.getKeyIfPresent(from: params.adminKey)
        tx.autoRenewPeriod = try CommonParamsParser.getAutoRenewPeriodIfPresent(
            from: params.autoRenewPeriod, for: method)
        tx.expirationTime = try CommonParamsParser.getExpirationTimeIfPresent(
            from: params.expirationTime, for: method)
        tx.contractMemo = params.memo
        tx.autoRenewAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.autoRenewAccountId)
        tx.maxAutomaticTokenAssociations = params.maxAutomaticTokenAssociations
        tx.stakedAccountId = try CommonParamsParser.getAccountIdIfPresent(from: params.stakedAccountId)
        tx.stakedNodeId = try CommonParamsParser.getStakedNodeIdIfPresent(from: params.stakedNodeId, for: method)
            .map { Int64(bitPattern: $0) }
        tx.declineStakingReward = params.declineStakingReward
        try params.commonTransactionParams?.applyToTransaction(&tx)

        return try await SDKClient.client.executeTransactionAndGetJsonRpcStatus(tx)
    }
}
