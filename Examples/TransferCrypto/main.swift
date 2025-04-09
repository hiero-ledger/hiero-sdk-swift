// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = Client.forTestnet()

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let transactionResponse = try await TransferTransaction()
            .hbarTransfer("0.0.1001", 20)
            .hbarTransfer("0.0.6189", -20)
            .execute(client)

        // either of these values can be used to lookup transactions in an explorer such as
        //  Kabuto or DragonGlass; the transaction ID is generally more useful as it also contains a rough
        //  estimation of when the transaction was created (+/- 8 seconds) and the account that paid for
        //  transaction
        print("transaction id: \(transactionResponse.transactionId)")
        print("transaction hash: \(transactionResponse.transactionHash)")
    }
}
