// SPDX-License-Identifier: Apache-2.0

import Foundation
import XCTest

@testable import Hiero

final class NFTHookTypeUnitTests: XCTestCase {

    func test_AllCases() {
        // Given & When
        let allCases = NftHookType.allCases

        // Then
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.preHook))
        XCTAssertTrue(allCases.contains(.prePostHook))
        XCTAssertTrue(allCases.contains(.uninitialized))
    }

    func test_Description() {
        // Given & When & Then
        XCTAssertEqual(NftHookType.preHook.description, "PRE_HOOK")
        XCTAssertEqual(NftHookType.prePostHook.description, "PRE_POST_HOOK")
        XCTAssertEqual(NftHookType.uninitialized.description, "UNINITIALIZED")
    }

    func test_Equality() {
        // Given & When & Then
        XCTAssertEqual(NftHookType.preHook, NftHookType.preHook)
        XCTAssertEqual(NftHookType.prePostHook, NftHookType.prePostHook)
        XCTAssertEqual(NftHookType.uninitialized, NftHookType.uninitialized)

        XCTAssertNotEqual(NftHookType.preHook, NftHookType.prePostHook)
        XCTAssertNotEqual(NftHookType.preHook, NftHookType.uninitialized)
        XCTAssertNotEqual(NftHookType.prePostHook, NftHookType.uninitialized)
    }

    func test_Hashable() {
        // Given
        let set: Set<NftHookType> = [.preHook, .prePostHook, .uninitialized]

        // When & Then
        XCTAssertEqual(set.count, 3)
        XCTAssertTrue(set.contains(.preHook))
        XCTAssertTrue(set.contains(.prePostHook))
        XCTAssertTrue(set.contains(.uninitialized))
    }
}
