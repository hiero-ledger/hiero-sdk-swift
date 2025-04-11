// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        print("Getting address book for \(env.networkName)")

        let results = try await NodeAddressBookQuery()
            .setFileId(FileId.addressBook)
            .execute(client)

        print(results)
    }
}
