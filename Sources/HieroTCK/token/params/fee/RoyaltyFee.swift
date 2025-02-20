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

/// Struct to hold the parameters of a royalty fee.
internal struct RoyaltyFee {

    internal var numerator: String
    internal var denominator: String
    internal var fallbackFee: FixedFee? = nil

    internal init(_ params: [String: JSONObject], _ funcName: JSONRPCMethod) throws {
        self.numerator = try getRequiredJsonParameter("numerator", params, funcName)
        self.denominator = try getRequiredJsonParameter("denominator", params, funcName)
        self.fallbackFee = try getOptionalJsonParameter("fallbackFee", params, funcName).map {
            try FixedFee($0, funcName)
        }
    }

    /// Convert this RoyaltyFee to a Hedera RoyaltyFee.
    internal func toHederaRoyaltyFee(
        _ feeCollectorAccountID: AccountId, _ feeCollectorsExempt: Bool, _ funcName: JSONRPCMethod
    ) throws
        -> Hiero.RoyaltyFee
    {
        return Hiero.RoyaltyFee(
            numerator: try CommonParams.getNumerator(self.numerator, funcName),
            denominator: try CommonParams.getDenominator(self.denominator, funcName),
            fallbackFee: try self.fallbackFee?.toHederaFixedFee(feeCollectorAccountID, feeCollectorsExempt, funcName),
            feeCollectorAccountId: feeCollectorAccountID,
            allCollectorsAreExempt: feeCollectorsExempt
        )

    }
}
