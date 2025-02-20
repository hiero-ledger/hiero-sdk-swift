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

/// Struct to hold the parameters of a 'updateTokenFeeSchedule' JSON-RPC method call.
internal struct UpdateTokenFeeScheduleParams {

    internal var tokenId: String? = nil
    internal var customFees: [CustomFee]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.updateTokenFeeSchedule)
            self.customFees = try
                (getOptionalJsonParameter("customFees", params, JSONRPCMethod.updateTokenFeeSchedule)
                as [JSONObject]?)?.map {
                    try CustomFee(
                        getJson($0, "fee in custom fees list", JSONRPCMethod.updateTokenFeeSchedule),
                        JSONRPCMethod.updateTokenFeeSchedule)
                }
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter(
                    "commonTransactionParams", params, JSONRPCMethod.updateTokenFeeSchedule),
                JSONRPCMethod.updateTokenFeeSchedule)
        }
    }
}
