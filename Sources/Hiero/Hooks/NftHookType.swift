// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The type of account allowance hook invocation for an NFT transfer.
///
/// Determines when the hook is called relative to the `CryptoTransfer` business logic.
///
/// - For "pre" hooks, the hook's `allow(HookContext, ProposedTransfers)` method is called
///   once before the transfer.
/// - For "pre/post" hooks, `allowPre(HookContext, ProposedTransfers)` is called before the
///   transfer and `allowPost(HookContext, ProposedTransfers)` is called after.
public enum NftHookType: CaseIterable, Equatable, Hashable {
    /// Execute the allowance hook once before the transfer.
    case preHook

    /// Execute the allowance hook before and after the transfer.
    case prePostHook

    /// Hook type has not been set.
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
