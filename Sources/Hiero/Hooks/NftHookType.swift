// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Enumeration specifying the different types of hooks for NFTs.
public enum NftHookType: CaseIterable, Equatable, Hashable {
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
