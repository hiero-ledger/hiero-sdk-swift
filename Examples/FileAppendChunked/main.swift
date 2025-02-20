import Hiero
import HieroExampleUtilities
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        async let bigContents = HieroExampleUtilities.Resources.bigContents
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let response = try await FileCreateTransaction()
            .keys([.single(env.operatorKey.publicKey)])
            .contents("[sdk::swift::example::FileAppendChunked]\n\n".data(using: .utf8)!)
            .maxTransactionFee(2)
            .execute(client)

        let receipt = try await response.getReceipt(client)

        let fileId = receipt.fileId!

        print("fileId: \(fileId)")

        let responses = try await FileAppendTransaction()
            .nodeAccountIds([response.nodeAccountId])
            .fileId(fileId)
            .contents(bigContents.data(using: .utf8)!)
            .maxTransactionFee(5)
            .executeAll(client)

        _ = try await responses.last!.getReceipt(client)

        let contents = try await FileContentsQuery()
            .fileId(fileId)
            .execute(client)

        print("File content size according to `FileInfoQuery`: `\(contents.contents.count)` bytes")
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
