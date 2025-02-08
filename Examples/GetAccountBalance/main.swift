// SPDX-License-Identifier: Apache-2.0

import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        print(try await AccountBalanceQuery().accountId(1001).getCost(client))

        let balance = try await AccountBalanceQuery()
            .accountId("0.0.1001")
            .execute(client)

        print("balance = \(balance.hbars)")
    }
}

extension Environment {
    /// The name of the hedera network this example should be ran against.
    ///
    /// Testnet by default.
    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}
