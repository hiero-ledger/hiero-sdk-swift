// SPDX-License-Identifier: Apache-2.0

import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        client.setOperator(env.operatorAccountId, env.operatorKey)

        let response = try await FileContentsQuery()
            .fileId("0.0.34945328")
            .execute(client)

        let text = String(data: response.contents, encoding: .utf8)!

        print("contents = \(text)")
    }
}
