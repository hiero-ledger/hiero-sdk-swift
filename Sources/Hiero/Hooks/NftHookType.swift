// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Enumeration specifying the different types of hooks for NFTs.
public enum NftHookType: CaseIterable {
    /// Execute the hook before the transaction.
    case preHook

    /// Execute the hook before and after the transaction.
    case prePostHook

    /// Hook type uninitialized.
    case uninitialized
}

extension NftHookType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .preHook:
            return "PRE_HOOK"
        case .prePostHook:
            return "PRE_POST_HOOK"
        case .uninitialized:
            return "UNINITIALIZED"
        }
    }
}

extension NftHookType: Equatable {
    public static func == (lhs: NftHookType, rhs: NftHookType) -> Bool {
        switch (lhs, rhs) {
        case (.preHook, .preHook),
            (.prePostHook, .prePostHook),
            (.uninitialized, .uninitialized):
            return true
        default:
            return false
        }
    }
}

extension NftHookType: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .preHook:
            hasher.combine(0)
        case .prePostHook:
            hasher.combine(1)
        case .uninitialized:
            hasher.combine(2)
        }
    }
}
