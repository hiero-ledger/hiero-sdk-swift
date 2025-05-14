// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let newKey = PrivateKey.generateEd25519()

        print("private key = \(newKey)")
        print("public key = \(newKey.publicKey)")

        let response = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(newKey.publicKey))
            .initialBalance(5)
            .execute(client)

        let receipt = try await response.getReceipt(client)
        let newAccountId = receipt.accountId!

        print("account address = \(newAccountId)")
    }
}
