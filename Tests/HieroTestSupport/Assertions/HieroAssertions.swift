// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import XCTest

/// Assert that an async expression throws an HError.
///
/// Use this to verify that Hiero SDK operations fail with the expected error type.
///
/// ## Usage
/// ```swift
/// await assertThrowsHErrorAsync(
///     try await AccountCreateTransaction().execute(testEnv.client),
///     "expected error creating account"
/// ) { error in
///     guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
///         XCTFail("Expected transactionPreCheckStatus error")
///         return
///     }
///     XCTAssertEqual(status, .keyRequired)
/// }
/// ```
///
/// - Parameters:
///   - expression: The async expression to evaluate
///   - message: Optional message displayed on failure
///   - file: Source file (auto-captured)
///   - line: Source line (auto-captured)
///   - errorHandler: Closure to inspect and assert on the thrown HError
public func assertThrowsHErrorAsync<T>(
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

// MARK: - Convenience Error Assertions

/// Assert that an async expression throws an HError with a specific receipt status.
///
/// This is a convenience wrapper for the common pattern of asserting receipt status errors
/// in integration tests.
///
/// ## Usage
/// ```swift
/// await assertReceiptStatus(
///     try await TokenCreateTransaction()
///         .symbol("TEST")
///         .treasuryAccountId(testEnv.operator.accountId)
///         .execute(testEnv.client)
///         .getReceipt(testEnv.client),
///     .missingTokenName
/// )
/// ```
///
/// - Parameters:
///   - expression: The async expression to evaluate
///   - expectedStatus: The expected receipt status
///   - message: Optional message displayed on failure
///   - file: Source file (auto-captured)
///   - line: Source line (auto-captured)
public func assertReceiptStatus<T>(
    _ expression: @autoclosure () async throws -> T,
    _ expectedStatus: Status,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) async {
    let msg = message()
    await assertThrowsHErrorAsync(
        try await expression(),
        msg,
        file: file,
        line: line
    ) { error in
        guard case .receiptStatus(let status, transactionId: _) = error.kind else {
            let failMessage =
                "Expected receiptStatus error, got \(error.kind)"
                + (msg.isEmpty ? "" : " - \(msg)")
            XCTFail(failMessage, file: file, line: line)
            return
        }
        XCTAssertEqual(status, expectedStatus, file: file, line: line)
    }
}

/// Assert that an async expression throws an HError with a specific precheck status.
///
/// This is a convenience wrapper for the common pattern of asserting precheck status errors
/// in integration tests. Precheck errors occur before the transaction is submitted to consensus.
///
/// ## Usage
/// ```swift
/// await assertPrecheckStatus(
///     try await AccountCreateTransaction()
///         .execute(testEnv.client),
///     .keyRequired
/// )
/// ```
///
/// - Parameters:
///   - expression: The async expression to evaluate
///   - expectedStatus: The expected precheck status
///   - message: Optional message displayed on failure
///   - file: Source file (auto-captured)
///   - line: Source line (auto-captured)
public func assertPrecheckStatus<T>(
    _ expression: @autoclosure () async throws -> T,
    _ expectedStatus: Status,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) async {
    let msg = message()
    await assertThrowsHErrorAsync(
        try await expression(),
        msg,
        file: file,
        line: line
    ) { error in
        guard case .transactionPreCheckStatus(let status, transactionId: _) = error.kind else {
            let failMessage =
                "Expected transactionPreCheckStatus error, got \(error.kind)"
                + (msg.isEmpty ? "" : " - \(msg)")
            XCTFail(failMessage, file: file, line: line)
            return
        }
        XCTAssertEqual(status, expectedStatus, file: file, line: line)
    }
}
