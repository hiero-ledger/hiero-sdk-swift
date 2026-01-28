// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Enumeration specifying the different types of hooks for fungible tokens (including HBAR).
public enum FungibleHookType: CaseIterable {
    /// Execute the allowance hook before the transaction.
    case preTxAllowanceHook

    /// Execute the allowance hook before and after the transaction.
    case prePostTxAllowanceHook

    /// Hook type not set.
    case uninitialized
}

extension FungibleHookType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .preTxAllowanceHook:
            return "PRE_TX_ALLOWANCE_HOOK"
        case .prePostTxAllowanceHook:
            return "PRE_POST_TX_ALLOWANCE_HOOK"
        case .uninitialized:
            return "UNINITIALIZED"
        }
    }
}

extension FungibleHookType: Equatable {
    public static func == (lhs: FungibleHookType, rhs: FungibleHookType) -> Bool {
        switch (lhs, rhs) {
        case (.preTxAllowanceHook, .preTxAllowanceHook),
            (.prePostTxAllowanceHook, .prePostTxAllowanceHook),
            (.uninitialized, .uninitialized):
            return true
        default:
            return false
        }
    }
}

extension FungibleHookType: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .preTxAllowanceHook:
            hasher.combine(0)
        case .prePostTxAllowanceHook:
            hasher.combine(1)
        case .uninitialized:
            hasher.combine(2)
        }
    }
}
