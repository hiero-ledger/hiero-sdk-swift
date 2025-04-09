// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let response = try await AccountDeleteTransaction()
            .transferAccountId("0.0.6189")
            .accountId("0.0.34952813")
            .execute(client)

        _ = try await response.getReceipt(client)
    }
}
