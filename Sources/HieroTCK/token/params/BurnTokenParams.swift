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

/// Struct to hold the parameters of a 'burnToken' JSON-RPC method call.
internal struct BurnTokenParams {

    internal var tokenId: String? = nil
    internal var amount: String? = nil
    internal var serialNumbers: [String]? = nil
    internal var commonTransactionParams: CommonTransactionParams? = nil

    internal init(_ request: JSONRequest) throws {
        if let params = try getOptionalParams(request) {
            self.tokenId = try getOptionalJsonParameter("tokenId", params, JSONRPCMethod.burnToken)
            self.amount = try getOptionalJsonParameter("amount", params, JSONRPCMethod.burnToken)
            self.serialNumbers = try
                (getOptionalJsonParameter("serialNumbers", params, JSONRPCMethod.burnToken) as [JSONObject]?)?.map {
                    try getJson($0, "serial number in serialNumbers list", JSONRPCMethod.burnToken)
                }
            self.commonTransactionParams = try CommonTransactionParams(
                try getOptionalJsonParameter("commonTransactionParams", params, JSONRPCMethod.burnToken),
                JSONRPCMethod.burnToken)
        }
    }
}
