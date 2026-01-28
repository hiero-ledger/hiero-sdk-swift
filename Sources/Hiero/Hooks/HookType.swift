// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// Enumeration specifying the different types of hooks.
public enum HookType {
    /// Execute the hook before the transaction.
    case preHook

    /// Execute the hook before and after the transaction.
    case prePostHook

    /// Execute the hook for the sender before the transaction.
    case preHookSender

    /// Execute the hook for the sender before and after the transaction.
    case prePostHookSender

    /// Execute the hook for the receiver before the transaction.
    case preHookReceiver

    /// Execute the hook for the receiver before and after the transaction.
    case prePostHookReceiver
}
