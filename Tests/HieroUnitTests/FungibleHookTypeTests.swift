// SPDX-License-Identifier: Apache-2.0

import Foundation
import XCTest

@testable import Hiero

internal final class FungibleHookTypeUnitTests: XCTestCase {

    internal func test_AllCases() {
        let allCases = FungibleHookType.allCases

        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.preHookSender))
        XCTAssertTrue(allCases.contains(.prePostHookSender))
        XCTAssertTrue(allCases.contains(.preHookReceiver))
        XCTAssertTrue(allCases.contains(.prePostHookReceiver))
        XCTAssertTrue(allCases.contains(.uninitialized))
    }

    internal func test_Description() {
        XCTAssertEqual(FungibleHookType.preHookSender.description, "PRE_HOOK_SENDER")
        XCTAssertEqual(FungibleHookType.prePostHookSender.description, "PRE_POST_HOOK_SENDER")
        XCTAssertEqual(FungibleHookType.preHookReceiver.description, "PRE_HOOK_RECEIVER")
        XCTAssertEqual(FungibleHookType.prePostHookReceiver.description, "PRE_POST_HOOK_RECEIVER")
        XCTAssertEqual(FungibleHookType.uninitialized.description, "UNINITIALIZED")
    }

    internal func test_Equality() {
        XCTAssertEqual(FungibleHookType.preHookSender, FungibleHookType.preHookSender)
        XCTAssertEqual(FungibleHookType.prePostHookSender, FungibleHookType.prePostHookSender)
        XCTAssertEqual(FungibleHookType.preHookReceiver, FungibleHookType.preHookReceiver)
        XCTAssertEqual(FungibleHookType.prePostHookReceiver, FungibleHookType.prePostHookReceiver)
        XCTAssertEqual(FungibleHookType.uninitialized, FungibleHookType.uninitialized)

        XCTAssertNotEqual(FungibleHookType.preHookSender, FungibleHookType.prePostHookSender)
        XCTAssertNotEqual(FungibleHookType.preHookSender, FungibleHookType.preHookReceiver)
        XCTAssertNotEqual(FungibleHookType.preHookSender, FungibleHookType.uninitialized)
    }

    internal func test_Hashable() {
        let set: Set<FungibleHookType> = [
            .preHookSender, .prePostHookSender,
            .preHookReceiver, .prePostHookReceiver,
            .uninitialized,
        ]

        XCTAssertEqual(set.count, 5)
        XCTAssertTrue(set.contains(.preHookSender))
        XCTAssertTrue(set.contains(.prePostHookSender))
        XCTAssertTrue(set.contains(.preHookReceiver))
        XCTAssertTrue(set.contains(.prePostHookReceiver))
        XCTAssertTrue(set.contains(.uninitialized))
    }
}
