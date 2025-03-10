// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        print("Getting address book for \(env.networkName)")

        let results = try await NodeAddressBookQuery()
            .setFileId(FileId.addressBook)
            .execute(client)

        print(results)
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
