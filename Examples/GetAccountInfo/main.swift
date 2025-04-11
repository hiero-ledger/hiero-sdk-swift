// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let id = AccountId(num: 1001)

        let info = try await AccountInfoQuery()
            .accountId(id)
            .execute(client)

        print("balance = \(info.balance)")
    }
}
