// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The type of account allowance hook invocation for a fungible token transfer (including HBAR).
///
/// Determines when the hook is called relative to the `CryptoTransfer` business logic and
/// whether it applies to the sending or receiving account.
///
/// - For "pre" hooks, the hook's `allow(HookContext, ProposedTransfers)` method is called
///   once before the transfer.
/// - For "pre/post" hooks, `allowPre(HookContext, ProposedTransfers)` is called before the
///   transfer and `allowPost(HookContext, ProposedTransfers)` is called after.
public enum FungibleHookType: CaseIterable, Equatable, Hashable {
    /// Execute the allowance hook once before the transfer for the sending account.
    case preHookSender

    /// Execute the allowance hook before and after the transfer for the sending account.
    case prePostHookSender

    /// Execute the allowance hook once before the transfer for the receiving account.
    case preHookReceiver

    /// Execute the allowance hook before and after the transfer for the receiving account.
    case prePostHookReceiver

    /// Hook type has not been set.
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
