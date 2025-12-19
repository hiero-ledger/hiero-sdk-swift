// SPDX-License-Identifier: Apache-2.0

import HieroTestSupport
import XCTest

@testable import Hiero

internal final class ClientUnitTests: HieroUnitTestCase {
    internal func test_GetShardRealm() throws {
        let shard: UInt64 = 1
        let realm: UInt64 = 2
        let client = try Client.forNetwork([String: AccountId](), shard: shard, realm: realm)

        XCTAssertEqual(client.getShard(), shard)
        XCTAssertEqual(client.getRealm(), realm)
    }

    // MARK: - gRPC Deadline Tests

    internal func test_GrpcDeadlineDefaultValue() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // Default gRPC deadline should be 10 seconds
        XCTAssertEqual(client.grpcDeadline, 10.0)
    }

    internal func test_GrpcDeadlineSetViaFluentSetter() throws {
        let client = try Client.forNetwork([String: AccountId]())
        try client.setGrpcDeadline(15.0)

        XCTAssertEqual(client.grpcDeadline, 15.0)
    }

    internal func test_GrpcDeadlineFluentSetterReturnsClient() throws {
        let client = try Client.forNetwork([String: AccountId]())
        let returnedClient = try client.setGrpcDeadline(5.0)

        // Fluent setter should return the same client instance
        XCTAssertTrue(client === returnedClient)
    }

    // MARK: - Request Timeout Tests

    internal func test_RequestTimeoutDefaultValue() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // Default request timeout should be 2 minutes (120 seconds)
        XCTAssertEqual(client.requestTimeout, 120.0)
    }

    internal func test_RequestTimeoutCanBeSetToNil() throws {
        let client = try Client.forNetwork([String: AccountId]())

        try client.setRequestTimeout(nil)

        XCTAssertNil(client.requestTimeout)
    }

    internal func test_RequestTimeoutCanBeSetWhenGreaterThanGrpcDeadline() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // grpcDeadline defaults to 10s, so 60s should be fine
        try client.setRequestTimeout(60.0)

        XCTAssertEqual(client.requestTimeout, 60.0)
    }

    // MARK: - Timeout Relationship Tests

    internal func test_GrpcDeadlineCanBeSetWhenLessThanRequestTimeout() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // requestTimeout defaults to 120s
        try client.setGrpcDeadline(30.0)

        XCTAssertEqual(client.grpcDeadline, 30.0)
    }

    internal func test_GrpcDeadlineCanEqualRequestTimeout() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // Set both to the same value
        try client.setRequestTimeout(30.0)
        try client.setGrpcDeadline(30.0)

        XCTAssertEqual(client.grpcDeadline, 30.0)
        XCTAssertEqual(client.requestTimeout, 30.0)
    }

    internal func test_GrpcDeadlineCanBeSetWhenRequestTimeoutIsNil() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // Setting requestTimeout to nil removes the constraint
        try client.setRequestTimeout(nil)
        try client.setGrpcDeadline(300.0)  // Can set any value when requestTimeout is nil

        XCTAssertEqual(client.grpcDeadline, 300.0)
    }

    // MARK: - Validation Tests

    internal func test_SetRequestTimeoutThrowsWhenShorterThanGrpcDeadline() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // Default grpcDeadline is 10s
        XCTAssertEqual(client.grpcDeadline, 10.0)

        // Trying to set requestTimeout to less than grpcDeadline should throw
        XCTAssertThrowsError(try client.setRequestTimeout(5.0)) { error in
            guard let hError = error as? HError else {
                XCTFail("Expected HError, got \(type(of: error))")
                return
            }
            XCTAssertEqual(hError.kind, .illegalState)
            XCTAssertTrue(hError.description.contains("requestTimeout"))
            XCTAssertTrue(hError.description.contains("grpcDeadline"))
        }

        // requestTimeout should remain unchanged
        XCTAssertEqual(client.requestTimeout, 120.0)
    }

    internal func test_SetGrpcDeadlineThrowsWhenLongerThanRequestTimeout() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // Set a short requestTimeout first
        try client.setRequestTimeout(15.0)
        XCTAssertEqual(client.requestTimeout, 15.0)

        // Trying to set grpcDeadline to more than requestTimeout should throw
        XCTAssertThrowsError(try client.setGrpcDeadline(20.0)) { error in
            guard let hError = error as? HError else {
                XCTFail("Expected HError, got \(type(of: error))")
                return
            }
            XCTAssertEqual(hError.kind, .illegalState)
            XCTAssertTrue(hError.description.contains("grpcDeadline"))
            XCTAssertTrue(hError.description.contains("requestTimeout"))
        }

        // grpcDeadline should remain unchanged
        XCTAssertEqual(client.grpcDeadline, 10.0)
    }

    internal func test_SetRequestTimeoutSucceedsWhenEqualToGrpcDeadline() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // grpcDeadline defaults to 10s, so setting requestTimeout to 10s should work
        try client.setRequestTimeout(10.0)

        XCTAssertEqual(client.requestTimeout, 10.0)
    }

    internal func test_SetGrpcDeadlineSucceedsWhenEqualToRequestTimeout() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // Set requestTimeout to 15s
        try client.setRequestTimeout(15.0)

        // Setting grpcDeadline to exactly 15s should work
        try client.setGrpcDeadline(15.0)

        XCTAssertEqual(client.grpcDeadline, 15.0)
    }

    internal func test_SetRequestTimeoutToNilSucceeds() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // Setting requestTimeout to nil should always work (removes constraint)
        try client.setRequestTimeout(nil)

        XCTAssertNil(client.requestTimeout)
    }

    internal func test_SetGrpcDeadlineSucceedsWhenRequestTimeoutIsNil() throws {
        let client = try Client.forNetwork([String: AccountId]())

        // Remove requestTimeout constraint
        try client.setRequestTimeout(nil)

        // Now any grpcDeadline value should work
        try client.setGrpcDeadline(300.0)

        XCTAssertEqual(client.grpcDeadline, 300.0)
    }
}
