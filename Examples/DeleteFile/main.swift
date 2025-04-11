// SPDX-License-Identifier: Apache-2.0

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

        // The file is required to be a byte array,
        // you can easily use the bytes of a file instead.
        let fileContents = "Hiero hashgraph is great!"

        let receipt = try await FileCreateTransaction()
            .keys([.single(env.operatorKey.publicKey)])
            .contents(fileContents.data(using: .utf8)!)
            .maxTransactionFee(2)
            .execute(client).getReceipt(client)

        let newFileId = receipt.fileId!

        print("file: \(newFileId)")

        _ = try await FileDeleteTransaction().fileId(newFileId).execute(client).getReceipt(client)

        print("File deleted successfully")
    }
}
