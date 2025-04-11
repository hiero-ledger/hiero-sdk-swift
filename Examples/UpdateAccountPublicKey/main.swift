import Foundation
import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        // First, we create a new account so we don't affect our account

        let key1 = PrivateKey.generateEd25519()
        let key2 = PrivateKey.generateEd25519()

        let createResponse = try await AccountCreateTransaction()
            .keyWithoutAlias(.single(key1.publicKey))
            .initialBalance(1)
            .execute(client)

        print("transaction id: \(createResponse.transactionId)")

        let accountId = try await createResponse.getReceipt(client).accountId!

        print("new account id: `\(accountId)`")
        print("account key: `\(key1.publicKey)`")

        print(":: update public key of account `\(accountId)`")
        print("set key = `\(key2.publicKey)`")

        // note that we have to sign with both the new key (key2) and the old key (key1).
        let updateResponse = try await AccountUpdateTransaction()
            .accountId(accountId)
            .key(.single(key2.publicKey))
            .sign(key1)
            .sign(key2)
            .execute(client)

        print("transaction id: \(updateResponse.transactionId)")

        _ = try await updateResponse.getReceipt(client)

        print(":: run AccountInfoQuery and check our current key")

        let info = try await AccountInfoQuery(accountId: accountId).execute(client)

        print("key: \(info.key)")
    }
}

// extension Environment {
//     /// Account ID for the operator to use in this example.
//     internal var operatorAccountId: AccountId {
//         AccountId(self["OPERATOR_ID"]!.stringValue)!
//     }

//     /// Private key for the operator to use in this example.
//     internal var operatorKey: PrivateKey {
//         PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
//     }

//     /// The name of the hedera network this example should be ran against.
//     ///
//     /// Testnet by default.
//     internal var networkName: String {
//         self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
//     }
// }
