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

import Foundation
import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        // Defaults the operator account ID and key such that all generated transactions will be paid for
        // by this account and be signed by this key
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Generate a Ed25519 private, public key pair
        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()

        print("private key 1 = \(key1)")
        print("public key 1 = \(key1.publicKey)")
        print("private key 2 = \(key2)")
        print("public key 2 = \(key2.publicKey)")

        let newAccountId = try await AccountCreateTransaction()
            .key(.keyList([.single(key1.publicKey), .single(key2.publicKey)]))
            .initialBalance(.fromTinybars(1000))
            .execute(client)
            .getReceipt(client)
            .accountId!

        print("new account ID: \(newAccountId)")

        let tx = TransferTransaction()
            .hbarTransfer(newAccountId, -Hbar(1))
            .hbarTransfer(env.operatorAccountId, Hbar(1))

        let response =
            try await tx
            .schedule()
            .expirationTime(.now + .days(1))
            .isWaitForExpiry(true)
            .execute(client)

        print("scheduled transaction ID = \(response.transactionId)")

        let scheduleId = try await response.getReceipt(client).scheduleId!
        print("schedule ID = \(scheduleId)")

        let record = try await response.getRecord(client)
        print("record = \(record)")

        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(client)
            .sign(key1)
            .execute(client)
            .getReceipt(client)

        let info = try await ScheduleInfoQuery()
            .scheduleId(scheduleId)
            .execute(client)

        print("schedule info = \(info)")

        _ = try await ScheduleSignTransaction()
            .scheduleId(scheduleId)
            .freezeWith(client)
            .sign(key2)
            .execute(client)
            .getReceipt(client)

        let transactionId = response.transactionId

        print("The following link should query the mirror node for the scheduled transaction:")

        let transactionIdString =
            "\(transactionId.accountId)-\(transactionId.validStart.seconds)-\(transactionId.validStart.subSecondNanos)"

        print("https://\(env.networkName).mirrornode.hedera.com/api/v1/transactions/\(transactionIdString)")
    }
}

extension Environment {
    /// Account ID for the operator to use in this example.
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    /// Private key for the operator to use in this example.
    internal var operatorKey: PrivateKey {
        PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
    }

    /// The name of the hedera network this example should be ran against.
    ///
    /// Testnet by default.
    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
