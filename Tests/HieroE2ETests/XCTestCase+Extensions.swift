// SPDX-License-Identifier: Apache-2.0

import XCTest

import struct Hiero.HError
import struct Hiero.Hbar

extension XCTestCase {
    internal func makeAccount(_ testEnv: NonfreeTestEnvironment, balance: Hbar = 0) async throws -> Account {
        let account = try await Account.create(testEnv, balance: balance)

        addTeardownBlock {
            try await account.delete(testEnv)
        }

        return account
    }

    internal func assertThrowsHErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line,
        _ errorHandler: (_ error: HError) -> Void = { _ in }
    ) async {
        do {
            _ = try await expression()

            let message = message()

            var compactDescription: String = "assertThrowsHErrorAsync failed: did not throw an error"

            if !message.isEmpty {
                compactDescription += " - \(message)"
            }

            XCTFail(compactDescription, file: file, line: line)

        } catch let error as HError {
            errorHandler(error)
        } catch {
            XCTFail("assertThrowsHErrorAsync failed: did not throw a HError: \(error)", file: file, line: line)
        }
    }
}
