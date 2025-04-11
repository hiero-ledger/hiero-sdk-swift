// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Environment.load()
        let client = try Client.forName(env.networkName)

        // we need to return _something_ to say if stdin has been EOFed on us.
        guard try await manualChecksumValidation(client) else {
            return
        }

        // we need to return _something_ to say if stdin has been EOFed on us.
        guard try await automaticChecksumValidation(client) else {
            return
        }
    }

    private static func manualChecksumValidation(_ client: Client) async throws -> Bool {
        print("Example for manual checksum validation")

        var accountId: AccountId?

        while let accountIdTmp = try parseAccountId() {
            do {
                try accountIdTmp.validateChecksum(client)
            } catch let error as HError {
                print(error)
                if case .badEntityId(let error) = error.kind {
                    print(
                        "You entered \(error.shard).\(error.realm).\(error.num)-\(error.presentChecksum),",
                        "the expected checksum was \(error.expectedChecksum)"
                    )
                }

                continue
            }

            accountId = accountIdTmp
            break
        }

        guard let accountId = accountId else {
            return false
        }

        let balance = try await AccountBalanceQuery().accountId(accountId).execute(client)

        print("Balance for account \(accountId): \(balance)")

        return true
    }

    private static func automaticChecksumValidation(_ client: Client) async throws -> Bool {
        print("Example for automatic checksum validation")
        client.setAutoValidateChecksums(true)

        guard let accountId = try parseAccountId() else {
            return false
        }

        let balance = try await AccountBalanceQuery().accountId(accountId).execute(client)

        print("Balance for account \(accountId): \(balance)")

        return true
    }

    private static func parseAccountId() throws -> AccountId? {
        while true {
            print("Enter an account ID with checksum: ", terminator: "")
            guard let line = readLine() else {
                return nil
            }

            let accountId: AccountId
            do {
                accountId = try AccountId.fromString(line)
            } catch let error as HError where error.kind == .basicParse {
                print(error)
                continue
            }

            guard let checksum = accountId.checksum else {
                print("You must enter a checksum.")
                continue
            }

            print("The checksum entered was: \(checksum)")

            return accountId
        }
    }
}
