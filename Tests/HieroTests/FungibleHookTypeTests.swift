// SPDX-License-Identifier: Apache-2.0

import Foundation
import XCTest

@testable import Hiero

final class FungibleHookTypeUnitTests: XCTestCase {

    func test_AllCases() {
        // Given & When
        let allCases = FungibleHookType.allCases

        // Then
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.preTxAllowanceHook))
        XCTAssertTrue(allCases.contains(.prePostTxAllowanceHook))
        XCTAssertTrue(allCases.contains(.uninitialized))
    }

    func test_Description() {
        // Given & When & Then
        XCTAssertEqual(FungibleHookType.preTxAllowanceHook.description, "PRE_TX_ALLOWANCE_HOOK")
        XCTAssertEqual(FungibleHookType.prePostTxAllowanceHook.description, "PRE_POST_TX_ALLOWANCE_HOOK")
        XCTAssertEqual(FungibleHookType.uninitialized.description, "UNINITIALIZED")
    }

    func test_Equality() {
        // Given & When & Then
        XCTAssertEqual(FungibleHookType.preTxAllowanceHook, FungibleHookType.preTxAllowanceHook)
        XCTAssertEqual(FungibleHookType.prePostTxAllowanceHook, FungibleHookType.prePostTxAllowanceHook)
        XCTAssertEqual(FungibleHookType.uninitialized, FungibleHookType.uninitialized)

        XCTAssertNotEqual(FungibleHookType.preTxAllowanceHook, FungibleHookType.prePostTxAllowanceHook)
        XCTAssertNotEqual(FungibleHookType.preTxAllowanceHook, FungibleHookType.uninitialized)
        XCTAssertNotEqual(FungibleHookType.prePostTxAllowanceHook, FungibleHookType.uninitialized)
    }

    func test_Hashable() {
        // Given
        let set: Set<FungibleHookType> = [.preTxAllowanceHook, .prePostTxAllowanceHook, .uninitialized]

        // When & Then
        XCTAssertEqual(set.count, 3)
        XCTAssertTrue(set.contains(.preTxAllowanceHook))
        XCTAssertTrue(set.contains(.prePostTxAllowanceHook))
        XCTAssertTrue(set.contains(.uninitialized))
    }
}
