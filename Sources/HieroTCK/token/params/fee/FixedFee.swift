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
import Hiero

/// Struct to hold the parameters of a fixed fee.
internal struct FixedFee {

    internal var amount: String
    internal var denominatingTokenID: String? = nil

    internal init(_ params: [String: JSONObject], _ funcName: JSONRPCMethod) throws {
        self.amount = try getRequiredJsonParameter("amount", params, funcName)
        self.denominatingTokenID = try getOptionalJsonParameter("denominatingTokenId", params, funcName)
    }

    /// Convert this FixedFee to a Hedera FixedFee.
    internal func toHederaFixedFee(
        _ feeCollectorAccountID: AccountId, _ feeCollectorsExempt: Bool, _ funcName: JSONRPCMethod
    ) throws
        -> Hiero.FixedFee
    {
        /// Unwrap of self.amount can be safely forced since self.amount isn't optional.
        return Hiero.FixedFee(
            amount: try CommonParams.getSdkUInt64(self.amount, "amount", funcName)!,
            denominatingTokenId: try CommonParams.getTokenId(self.denominatingTokenID),
            feeCollectorAccountId: feeCollectorAccountID,
            allCollectorsAreExempt: feeCollectorsExempt
        )
    }
}
