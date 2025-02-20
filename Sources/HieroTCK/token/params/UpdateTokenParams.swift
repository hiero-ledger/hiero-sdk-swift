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

/// Struct to hold the parameters of a 'updateToken' JSON-RPC method call.
internal struct UpdateTokenParams {

    internal var tokenId: String? = nil
    internal var symbol: String? = nil
    internal var name: String? = nil
    internal var treasuryAccountId: String? = nil
    internal var adminKey: String? = nil
    internal var kycKey: String? = nil
    internal var freezeKey: String? = nil
    internal var wipeKey: String? = nil
    internal var supplyKey: String? = nil
    internal var autoRenewAccountId: String? = nil
    internal var autoRenewPeriod: String? = nil
    internal var expirationTime: String? = nil
    internal var memo: String? = nil
    internal var feeScheduleKey: String? = nil
    internal var pauseKey: String? = nil
    internal var metadata: String? = nil
    internal var metadataKey: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.updateToken)
            self.symbol = try getOptionalJsonParameter("symbol", params, JSONRPCMethod.updateToken)
            self.name = try getOptionalJsonParameter("name", params, JSONRPCMethod.updateToken)
            self.treasuryAccountId = try getOptionalJsonParameter(
                "treasuryAccountId", params, JSONRPCMethod.updateToken)
            self.adminKey = try getOptionalJsonParameter("adminKey", params, JSONRPCMethod.updateToken)
            self.kycKey = try getOptionalJsonParameter("kycKey", params, JSONRPCMethod.updateToken)
            self.freezeKey = try getOptionalJsonParameter("freezeKey", params, JSONRPCMethod.updateToken)
            self.wipeKey = try getOptionalJsonParameter("wipeKey", params, JSONRPCMethod.updateToken)
            self.supplyKey = try getOptionalJsonParameter("supplyKey", params, JSONRPCMethod.updateToken)
            self.autoRenewAccountId = try getOptionalJsonParameter(
                "autoRenewAccountId", params, JSONRPCMethod.updateToken)
            self.autoRenewPeriod = try getOptionalJsonParameter("autoRenewPeriod", params, JSONRPCMethod.updateToken)
            self.expirationTime = try getOptionalJsonParameter("expirationTime", params, JSONRPCMethod.updateToken)
            self.memo = try getOptionalJsonParameter("memo", params, JSONRPCMethod.updateToken)
            self.feeScheduleKey = try getOptionalJsonParameter("feeScheduleKey", params, JSONRPCMethod.updateToken)
            self.pauseKey = try getOptionalJsonParameter("pauseKey", params, JSONRPCMethod.updateToken)
            self.metadata = try getOptionalJsonParameter("metadata", params, JSONRPCMethod.updateToken)
            self.metadataKey = try getOptionalJsonParameter("metadataKey", params, JSONRPCMethod.updateToken)
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.updateToken),
                JSONRPCMethod.updateToken)
        }
    }
}
