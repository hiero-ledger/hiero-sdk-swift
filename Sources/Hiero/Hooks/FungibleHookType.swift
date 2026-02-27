// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Enumeration specifying the different types of hooks for fungible tokens (including HBAR).
public enum FungibleHookType: CaseIterable, Equatable, Hashable {
    /// Execute the allowance hook before the transaction for the sender.
    case preHookSender

    /// Execute the allowance hook before and after the transaction for the sender.
    case prePostHookSender

    /// Execute the allowance hook before the transaction for the receiver.
    case preHookReceiver

    /// Execute the allowance hook before and after the transaction for the receiver.
    case prePostHookReceiver

    /// Hook type not set.
    case uninitialized
}

extension FungibleHookType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .preHookSender:
            return "PRE_HOOK_SENDER"
        case .prePostHookSender:
            return "PRE_POST_HOOK_SENDER"
        case .preHookReceiver:
            return "PRE_HOOK_RECEIVER"
        case .prePostHookReceiver:
            return "PRE_POST_HOOK_RECEIVER"
        case .uninitialized:
            return "UNINITIALIZED"
        }
    }
}
