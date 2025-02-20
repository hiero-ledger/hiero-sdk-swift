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

/// Struct to hold the parameters for all transactions.
internal struct CommonTransactionParams {

    internal var transactionId: String? = nil
    internal var maxTransactionFee: Int64? = nil
    internal var validTransactionDuration: Int64? = nil
    internal var memo: String? = nil
    internal var regenerateTransactionId: Bool? = nil
    internal var signers: [String]? = nil

    internal init(_ parameters: [String: JSONObject]?, _ funcName: JSONRPCMethod) throws {
        if let params = parameters {
            self.transactionId = try getOptionalJsonParameter("transactionId", params, funcName)
            self.maxTransactionFee = try getOptionalJsonParameter("maxTransactionFee", params, funcName)
            self.validTransactionDuration = try getOptionalJsonParameter("validTransactionDuration", params, funcName)
            self.memo = try getOptionalJsonParameter("memo", params, funcName)
            self.regenerateTransactionId = try getOptionalJsonParameter("regenerateTransactionId", params, funcName)
            self.signers = try (getOptionalJsonParameter("signers", params, funcName) as [JSONObject]?)?.map {
                try getJson($0, "signer in signers list", funcName) as String
            }
        }
    }

    /// Fill in a Transaction's common parameters based on JSON input.
    internal func fillOutTransaction<T: Transaction>(_ transaction: inout T) throws {
        transaction.transactionId = try self.transactionId.flatMap { try TransactionId.fromString($0) }
        transaction.maxTransactionFee = self.maxTransactionFee.flatMap { Hbar.fromTinybars($0) }
        transaction.transactionValidDuration = self.validTransactionDuration.flatMap {
            Duration(seconds: toUint64($0))
        }
        transaction.transactionMemo = self.memo ?? transaction.transactionMemo
        transaction.regenerateTransactionId = self.regenerateTransactionId ?? transaction.regenerateTransactionId

        try self.signers.map {
            try transaction.freezeWith(SDKClient.client.getClient())
            try $0.forEach { transaction.sign(try PrivateKey.fromStringDer($0)) }
        }

    }
}
