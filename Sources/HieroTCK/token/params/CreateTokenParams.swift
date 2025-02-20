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

/// Struct to hold the parameters of a 'createToken' JSON-RPC method call.
internal struct CreateTokenParams {

    internal var name: String? = nil
    internal var symbol: String? = nil
    internal var decimals: UInt32? = nil
    internal var initialSupply: String? = nil
    internal var treasuryAccountId: String? = nil
    internal var adminKey: String? = nil
    internal var kycKey: String? = nil
    internal var freezeKey: String? = nil
    internal var wipeKey: String? = nil
    internal var supplyKey: String? = nil
    internal var freezeDefault: Bool? = nil
    internal var expirationTime: String? = nil
    internal var autoRenewAccountId: String? = nil
    internal var autoRenewPeriod: String? = nil
    internal var memo: String? = nil
    internal var tokenType: String? = nil
    internal var supplyType: String? = nil
    internal var maxSupply: String? = nil
    internal var feeScheduleKey: String? = nil
    internal var customFees: [CustomFee]? = nil
    internal var pauseKey: String? = nil
    internal var metadata: String? = nil
    internal var metadataKey: String? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.name = try getOptionalJsonParameter("name", params, JSONRPCMethod.createToken)
            self.symbol = try getOptionalJsonParameter("symbol", params, JSONRPCMethod.createToken)
            self.decimals = try getOptionalJsonParameter("decimals", params, JSONRPCMethod.createToken)
            self.initialSupply = try getOptionalJsonParameter("initialSupply", params, JSONRPCMethod.createToken)
            self.treasuryAccountId = try getOptionalJsonParameter(
                "treasuryAccountId", params, JSONRPCMethod.createToken)
            self.adminKey = try getOptionalJsonParameter("adminKey", params, JSONRPCMethod.createToken)
            self.kycKey = try getOptionalJsonParameter("kycKey", params, JSONRPCMethod.createToken)
            self.freezeKey = try getOptionalJsonParameter("freezeKey", params, JSONRPCMethod.createToken)
            self.wipeKey = try getOptionalJsonParameter("wipeKey", params, JSONRPCMethod.createToken)
            self.supplyKey = try getOptionalJsonParameter("supplyKey", params, JSONRPCMethod.createToken)
            self.freezeDefault = try getOptionalJsonParameter("freezeDefault", params, JSONRPCMethod.createToken)
            self.expirationTime = try getOptionalJsonParameter("expirationTime", params, JSONRPCMethod.createToken)
            self.autoRenewAccountId = try getOptionalJsonParameter(
                "autoRenewAccountId", params, JSONRPCMethod.createToken)
            self.autoRenewPeriod = try getOptionalJsonParameter("autoRenewPeriod", params, JSONRPCMethod.createToken)
            self.memo = try getOptionalJsonParameter("memo", params, JSONRPCMethod.createToken)
            self.tokenType = try getOptionalJsonParameter("tokenType", params, JSONRPCMethod.createToken)
            self.supplyType = try getOptionalJsonParameter("supplyType", params, JSONRPCMethod.createToken)
            self.maxSupply = try getOptionalJsonParameter("maxSupply", params, JSONRPCMethod.createToken)
            self.feeScheduleKey = try getOptionalJsonParameter("feeScheduleKey", params, JSONRPCMethod.createToken)
            self.customFees = try
                (getOptionalJsonParameter("customFees", params, JSONRPCMethod.createToken) as [JSONObject]?)?
                .map {
                    try CustomFee(
                        getJson($0, "fee in custom fees list", JSONRPCMethod.createToken),
                        JSONRPCMethod.createToken)
                }
            self.pauseKey = try getOptionalJsonParameter("pauseKey", params, JSONRPCMethod.createToken)
            self.metadata = try getOptionalJsonParameter("metadata", params, JSONRPCMethod.createToken)
            self.metadataKey = try getOptionalJsonParameter("metadataKey", params, JSONRPCMethod.createToken)
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.createToken),
                JSONRPCMethod.createToken)
        }
    }
}
