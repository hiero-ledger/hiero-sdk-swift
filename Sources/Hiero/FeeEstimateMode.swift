// SPDX-License-Identifier: Apache-2.0

/// The mode of fee estimation for `FeeEstimateQuery`.
///
/// This determines how the mirror node calculates the fee estimate.
public enum FeeEstimateMode: Sendable, Equatable, Hashable {
    /// Estimate based on the transaction's properties plus the latest known network state.
    ///
    /// This mode checks current state such as whether accounts exist, token associations,
    /// and other state-dependent factors. This is the default mode and provides the most
    /// accurate estimate for transactions that will be submitted immediately.
    case state

    /// Estimate based solely on the transaction's inherent properties.
    ///
    /// This mode ignores state-dependent factors and estimates based only on
    /// transaction size, signatures, keys, and other intrinsic properties.
    /// Useful when you want a baseline estimate without state dependencies.
    case intrinsic
}
