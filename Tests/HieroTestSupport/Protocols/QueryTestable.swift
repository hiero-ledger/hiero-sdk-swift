// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroProtobufs
import SnapshotTesting
import XCTest

/// Protocol for query tests that provides common serialization testing functionality.
///
/// Conforming types must provide a factory method that creates and serializes a query.
/// The protocol provides a default implementation for snapshot testing.
///
/// ## Usage
/// ```swift
/// import HieroTestSupport
/// @testable import Hiero
///
/// internal final class MyQueryTests: HieroUnitTestCase, QueryTestable {
///     static func makeQueryProto() -> Proto_Query {
///         MyQuery(someId: 5005).toQueryProtobufWith(.init())
///     }
///
///     func test_Serialize() throws {
///         assertQuerySerializes()
///     }
/// }
/// ```
///
/// For queries with multiple configurations (e.g., AccountBalanceQuery with accountId vs contractId),
/// use the protocol for the primary variant and manual `SnapshotTesting.assertSnapshot()` for others:
///
/// ```swift
/// internal final class AccountBalanceQueryTests: HieroUnitTestCase, QueryTestable {
///     static func makeQueryProto() -> Proto_Query {
///         AccountBalanceQuery(accountId: 5005).toQueryProtobufWith(.init())  // Primary variant
///     }
///
///     func test_Serialize() throws {
///         assertQuerySerializes()  // Tests accountId variant
///     }
///
///     func test_SerializeWithContractId() {  // Manual test for other variant
///         let proto = AccountBalanceQuery(contractId: 5005).toQueryProtobufWith(.init())
///         SnapshotTesting.assertSnapshot(of: proto, as: .description)
///     }
/// }
/// ```
public protocol QueryTestable: XCTestCase {
    /// Creates a query and returns its protobuf representation.
    ///
    /// This factory method should create a fully configured query and convert it to Proto_Query.
    ///
    /// - Returns: The query's protobuf representation
    static func makeQueryProto() throws -> Proto_Query
}

extension QueryTestable {
    /// Asserts that the query serializes correctly by comparing against a snapshot.
    ///
    /// This method calls `makeQueryProto()` and compares the result against a stored snapshot.
    ///
    /// - Parameters:
    ///   - file: Source file (auto-captured)
    ///   - testName: Test function name (auto-captured)
    ///   - line: Source line (auto-captured)
    public func assertQuerySerializes(
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) throws {
        let proto = try Self.makeQueryProto()

        SnapshotTesting.assertSnapshot(
            of: proto,
            as: .description,
            file: file,
            testName: testName,
            line: line
        )
    }
}
