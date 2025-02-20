/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

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
