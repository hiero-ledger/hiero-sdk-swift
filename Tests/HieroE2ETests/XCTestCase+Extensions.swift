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
        source: XCTSourceCodeContext = .init(),
        _ errorHandler: (_ error: HError) -> Void = { _ in }
    ) async {
        do {
            _ = try await expression()

            // XCTFail("abc")

            let message = message()

            var compactDescription: String = "\(#function) failed: did not throw an error"

            if !message.isEmpty {
                compactDescription += " - \(message)"
            }

            self.record(
                XCTIssue(
                    type: .assertionFailure,
                    compactDescription: compactDescription,
                    sourceCodeContext: source
                )
            )

        } catch let error as HError {
            errorHandler(error)
        } catch {
            self.record(
                XCTIssue(
                    type: .assertionFailure,
                    compactDescription: "\(#function) failed: did not throw a HError: \(error)",
                    sourceCodeContext: source,
                    associatedError: error
                )
            )
        }
    }
}
