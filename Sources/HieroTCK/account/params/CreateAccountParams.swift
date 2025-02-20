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

/// Struct to hold the parameters of a 'createAccount' JSON-RPC method call.
internal struct CreateAccountParams {

    internal var key: String? = nil
    internal var initialBalance: String? = nil
    internal var receiverSignatureRequired: Bool? = nil
    internal var autoRenewPeriod: String? = nil
    internal var memo: String? = nil
    internal var maxAutoTokenAssociations: Int32? = nil
    internal var stakedAccountId: String? = nil
    internal var stakedNodeId: String? = nil
    internal var declineStakingReward: Bool? = nil
    internal var alias: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.key = try getOptionalJsonParameter("key", params, JSONRPCMethod.createAccount)
            self.initialBalance = try getOptionalJsonParameter("initialBalance", params, JSONRPCMethod.createAccount)
            self.receiverSignatureRequired = try getOptionalJsonParameter(
                "receiverSignatureRequired", params, JSONRPCMethod.createAccount)
            self.autoRenewPeriod = try getOptionalJsonParameter("autoRenewPeriod", params, JSONRPCMethod.createAccount)
            self.memo = try getOptionalJsonParameter("memo", params, JSONRPCMethod.createAccount)
            self.maxAutoTokenAssociations = try getOptionalJsonParameter(
                "maxAutoTokenAssociations", params, JSONRPCMethod.createAccount)
            self.stakedAccountId = try getOptionalJsonParameter("stakedAccountId", params, JSONRPCMethod.createAccount)
            self.stakedNodeId = try getOptionalJsonParameter("stakedNodeId", params, JSONRPCMethod.createAccount)
            self.declineStakingReward = try getOptionalJsonParameter(
                "declineStakingReward", params, JSONRPCMethod.createAccount)
            self.alias = try getOptionalJsonParameter("alias", params, JSONRPCMethod.createAccount)
            self.commonTransactionParams = try CommonTransactionParams(
                getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.createAccount),
                JSONRPCMethod.createAccount)
        }
    }
}
