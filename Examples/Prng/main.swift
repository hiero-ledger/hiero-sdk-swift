// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        // Defaults the operator account ID and key such that all generated transactions will be paid for
        // by this account and be signed by this key
        client.setOperator(env.operatorAccountId, env.operatorKey)

        let transactionResponse = try await PrngTransaction()
            .range(100)
            .execute(client)

        let record = try await transactionResponse.getRecord(client)

        print("generated random number = \(String(describing: record.prngNumber))")

    }
}
