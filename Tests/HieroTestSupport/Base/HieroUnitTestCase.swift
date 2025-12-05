// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroProtobufs
/// Re-export HieroProtobufs for protobuf types in tests
@_exported import HieroProtobufs
import SnapshotTesting
/// Re-export SnapshotTesting so tests only need to import HieroTestSupport
@_exported import SnapshotTesting
import XCTest

// MARK: - Re-exports for convenience

/// Base class for unit tests (no network required).
///
/// Provides common utilities for unit testing Hiero SDK types.
/// For transaction tests, combine with `TransactionTestable` protocol.
/// For query tests, combine with `QueryTestable` protocol.
///
/// ## Usage
///
/// ### Basic Unit Test
/// ```swift
/// import HieroTestSupport
/// @testable import Hiero
///
/// internal final class MyTests: HieroUnitTestCase {
///     func test_Something() {
///         // Test code here
///     }
/// }
/// ```
///
/// ### Transaction Test with Protocol
/// ```swift
/// import HieroTestSupport
/// @testable import Hiero
///
/// internal final class MyTransactionTests: HieroUnitTestCase, TransactionTestable {
///     typealias TransactionType = MyTransaction
///
///     static func makeTransaction() throws -> MyTransaction {
///         try MyTransaction()
///             .nodeAccountIds(TestConstants.nodeAccountIds)
///             .transactionId(TestConstants.transactionId)
///             .freeze()
///             .sign(TestConstants.privateKey)
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
///
/// ### Query Test with Protocol
/// ```swift
/// import HieroTestSupport
/// @testable import Hiero
///
/// internal final class MyQueryTests: HieroUnitTestCase, QueryTestable {
///     static func makeQueryProto() throws -> Proto_Query {
///         MyQuery(someId: 5005).toQueryProtobufWith(.init())
///     }
///
///     func test_Serialize() throws {
///         try assertQuerySerializes()
///     }
/// }
/// ```
open class HieroUnitTestCase: HieroTestCase {

    open override func setUp() async throws {
        try await super.setUp()
    }
}
