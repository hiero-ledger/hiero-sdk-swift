// SPDX-License-Identifier: Apache-2.0

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

        // The file is required to be a byte array,
        // you can easily use the bytes of a file instead.
        let fileContents = "Hiero is great!"

        let response = try await FileCreateTransaction()
            .keys([.single(env.operatorKey.publicKey)])
            .contents(fileContents.data(using: .utf8)!)
            .maxTransactionFee(2)
            .execute(client)

        let receipt = try await response.getReceipt(client)

        print("file: \(String(describing: receipt.fileId))")
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
