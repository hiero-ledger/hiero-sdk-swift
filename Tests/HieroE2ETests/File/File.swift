// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

internal struct File {
    internal let fileId: FileId

    /// Creates a file with the given content.
    internal static func forContent(_ content: Data, _ testEnv: NonfreeTestEnvironment) async throws -> Self {
        try await testEnv.ratelimits.file()

        let receipt = try await FileCreateTransaction()
            .keys([.single(testEnv.operator.privateKey.publicKey)])
            .contents(content)
            .expirationTime(.now + .days(30))
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

        let fileId = try XCTUnwrap(receipt.fileId)

        return Self(fileId: fileId)
    }

    internal static func forContent(_ content: String, _ testEnv: NonfreeTestEnvironment) async throws -> Self {
        try await forContent(content.data(using: .utf8)!, testEnv)
    }

    internal func delete(_ testEnv: NonfreeTestEnvironment) async throws {
        try await testEnv.ratelimits.file()

        _ = try await FileDeleteTransaction(fileId: fileId)
            .execute(testEnv.client)
            .getReceipt(testEnv.client)

    }
}
