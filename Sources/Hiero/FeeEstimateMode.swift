// SPDX-License-Identifier: Apache-2.0

/// The mode of fee estimation.
public enum FeeEstimateMode: Sendable, Equatable, Hashable {
    /// Default: uses latest known state
    case state
    /// Ignores state-dependent factors
    case intrinsic
}
