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

/// Assert that an async expression throws an HError with a specific query payment precheck status.
///
/// This is a convenience wrapper for asserting query payment precheck errors in integration tests.
/// These errors occur when a query with a payment transaction fails precheck (e.g., insufficient fee).
///
/// ## Usage
/// ```swift
/// await assertQueryPaymentPrecheckStatus(
///     try await AccountInfoQuery(accountId: accountId)
///         .maxPaymentAmount(.fromTinybars(10000))
///         .paymentAmount(.fromTinybars(1))
///         .execute(testEnv.client),
///     .insufficientTxFee
/// )
/// ```
///
/// - Parameters:
///   - expression: The async expression to evaluate
///   - expectedStatus: The expected query payment precheck status
///   - message: Optional message displayed on failure
///   - file: Source file (auto-captured)
///   - line: Source line (auto-captured)
public func assertQueryPaymentPrecheckStatus<T>(
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
        guard case .queryPaymentPreCheckStatus(let status, transactionId: _) = error.kind else {
            let failMessage =
                "Expected queryPaymentPreCheckStatus error, got \(error.kind)"
                + (msg.isEmpty ? "" : " - \(msg)")
            XCTFail(failMessage, file: file, line: line)
            return
        }
        XCTAssertEqual(status, expectedStatus, file: file, line: line)
    }
}

/// Assert that an async expression throws an HError with a specific query (no payment) precheck status.
///
/// This is a convenience wrapper for asserting query precheck errors in integration tests.
/// These errors occur when a query without a payment fails precheck (e.g., invalid ID).
///
/// ## Usage
/// ```swift
/// await assertQueryNoPaymentPrecheckStatus(
///     try await AccountInfoQuery().execute(testEnv.client),
///     .invalidAccountID
/// )
/// ```
///
/// - Parameters:
///   - expression: The async expression to evaluate
///   - expectedStatus: The expected query precheck status
///   - message: Optional message displayed on failure
///   - file: Source file (auto-captured)
///   - line: Source line (auto-captured)
public func assertQueryNoPaymentPrecheckStatus<T>(
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
        guard case .queryNoPaymentPreCheckStatus(let status) = error.kind else {
            let failMessage =
                "Expected queryNoPaymentPreCheckStatus error, got \(error.kind)"
                + (msg.isEmpty ? "" : " - \(msg)")
            XCTFail(failMessage, file: file, line: line)
            return
        }
        XCTAssertEqual(status, expectedStatus, file: file, line: line)
    }
}

/// Assert that an async expression throws an HError for max query payment exceeded.
///
/// This is a convenience wrapper for asserting that a query fails because the estimated
/// cost exceeds the maximum payment amount set by the client.
///
/// ## Usage
/// ```swift
/// let query = AccountInfoQuery(accountId: accountId).maxPaymentAmount(.fromTinybars(1))
/// let cost = try await query.getCost(testEnv.client)
/// await assertMaxQueryPaymentExceeded(
///     try await query.execute(testEnv.client),
///     queryCost: cost,
///     maxQueryPayment: .fromTinybars(1)
/// )
/// ```
///
/// - Parameters:
///   - expression: The async expression to evaluate
///   - queryCost: The expected query cost
///   - maxQueryPayment: The expected max query payment that was exceeded
///   - message: Optional message displayed on failure
///   - file: Source file (auto-captured)
///   - line: Source line (auto-captured)
public func assertMaxQueryPaymentExceeded<T>(
    _ expression: @autoclosure () async throws -> T,
    queryCost: Hbar,
    maxQueryPayment: Hbar,
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
        XCTAssertEqual(
            error.kind,
            .maxQueryPaymentExceeded(queryCost: queryCost, maxQueryPayment: maxQueryPayment),
            msg.isEmpty ? "" : msg,
            file: file,
            line: line
        )
    }
}
