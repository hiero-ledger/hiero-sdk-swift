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

/// Struct to hold the parameters of a 'updateAccount' JSON-RPC method call.
internal struct UpdateAccountParams {

    internal var accountId: String? = nil
    internal var key: String? = nil
    internal var autoRenewPeriod: String? = nil
    internal var expirationTime: String? = nil
    internal var receiverSignatureRequired: Bool? = nil
    internal var memo: String? = nil
    internal var maxAutoTokenAssociations: Int32? = nil
    internal var stakedAccountId: String? = nil
    internal var stakedNodeId: String? = nil
    internal var declineStakingReward: Bool? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.accountId = try getOptionalJsonParameter("accountId", params, JSONRPCMethod.updateAccount)
            self.key = try getOptionalJsonParameter("key", params, JSONRPCMethod.updateAccount)
            self.autoRenewPeriod = try getOptionalJsonParameter("autoRenewPeriod", params, JSONRPCMethod.updateAccount)
            self.expirationTime = try getOptionalJsonParameter("expirationTime", params, JSONRPCMethod.updateAccount)
            self.receiverSignatureRequired = try getOptionalJsonParameter(
                "receiverSignatureRequired", params, JSONRPCMethod.updateAccount)
            self.memo = try getOptionalJsonParameter("memo", params, JSONRPCMethod.updateAccount)
            self.maxAutoTokenAssociations = try getOptionalJsonParameter(
                "maxAutoTokenAssociations", params, JSONRPCMethod.updateAccount)
            self.stakedAccountId = try getOptionalJsonParameter("stakedAccountId", params, JSONRPCMethod.updateAccount)
            self.stakedNodeId = try getOptionalJsonParameter("stakedNodeId", params, JSONRPCMethod.updateAccount)
            self.declineStakingReward = try getOptionalJsonParameter(
                "declineStakingReward", params, JSONRPCMethod.updateAccount)
            self.commonTransactionParams = try CommonTransactionParams(
                getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.updateAccount),
                JSONRPCMethod.updateAccount)
        }
    }
}
