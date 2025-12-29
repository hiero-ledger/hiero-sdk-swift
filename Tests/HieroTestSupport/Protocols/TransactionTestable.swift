// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroProtobufs
import SnapshotTesting
import XCTest

/// Protocol for transaction unit tests that share common testing patterns.
///
/// Conforming to this protocol provides default implementations for common
/// transaction tests like serialization and round-trip testing.
///
/// ## Usage
/// ```swift
/// internal final class TokenDeleteTransactionTests: HieroUnitTestCase, TransactionTestable {
///     typealias TransactionType = TokenDeleteTransaction
///
///     static func makeTransaction() throws -> TokenDeleteTransaction {
///         try TokenDeleteTransaction()
///             .nodeAccountIds(TestConstants.nodeAccountIds)
///             .transactionId(TestConstants.transactionId)
///             .sign(TestConstants.privateKey)
///             .tokenId("1.2.3")
///             .freeze()
///     }
///
///     func test_Serialize() throws {
///         try assertTransactionSerializes()
///     }
///
///     func test_ToFromBytes() throws {
///         try assertTransactionRoundTrips()
///     }
/// }
/// ```
public protocol TransactionTestable: XCTestCase {
    /// The transaction type being tested
    associatedtype TransactionType: Transaction

    /// Creates a fully configured transaction for testing.
    ///
    /// This should return a frozen, signed transaction ready for serialization tests.
    static func makeTransaction() throws -> TransactionType
}

// MARK: - Default Implementations

extension TransactionTestable {
    /// Asserts that the transaction serializes correctly using snapshot testing.
    ///
    /// This creates a transaction using `makeTransaction()`, extracts its protobuf body,
    /// and compares it against a stored snapshot.
    ///
    /// - Parameters:
    ///   - file: Source file (auto-captured)
    ///   - testName: Test function name (auto-captured)
    ///   - line: Source line (auto-captured)
    public func assertTransactionSerializes(
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) throws {
        let tx = try Self.makeTransaction()
        let protoBody = try tx.makeProtoBody()

        assertSnapshot(
            of: protoBody,
            as: .description,
            file: file,
            testName: testName,
            line: line
        )
    }

    /// Asserts that the transaction can be serialized and deserialized without data loss.
    ///
    /// This creates a transaction, converts it to bytes, deserializes it back,
    /// and compares the protobuf bodies for equality.
    ///
    /// - Parameters:
    ///   - file: Source file (auto-captured)
    ///   - line: Source line (auto-captured)
    public func assertTransactionRoundTrips(
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let tx = try Self.makeTransaction()
        let tx2 = try Transaction.fromBytes(tx.toBytes())

        XCTAssertEqual(
            try tx.makeProtoBody(),
            try tx2.makeProtoBody(),
            "Transaction protobuf bodies should match after round-trip",
            file: file,
            line: line
        )
    }
}
