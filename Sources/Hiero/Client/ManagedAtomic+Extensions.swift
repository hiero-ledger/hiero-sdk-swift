// SPDX-License-Identifier: Apache-2.0

import Atomics

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

// MARK: - Atomic Helpers

extension ManagedAtomic {
    /// Performs a read-copy-update operation atomically.
    ///
    /// This continuously retries until the update succeeds without interference from other threads.
    /// Uses a compare-and-swap loop with cooperative yielding to ensure thread-safe updates
    /// while being fair to other threads under contention.
    ///
    /// ## Implementation Details
    /// - First attempt uses `.weakCompareExchange` for better performance on architectures with LL/SC
    /// - Failed attempts yield to other threads to reduce CPU spinning and improve fairness
    /// - The transformation closure may be called multiple times if contention occurs
    ///
    /// ## Usage Example
    /// ```swift
    /// let atomicNetwork = ManagedAtomic<ConsensusNetwork>(network)
    /// let updated = atomicNetwork.readCopyUpdate { oldNetwork in
    ///     ConsensusNetwork.withAddresses(oldNetwork, addresses: newAddresses, eventLoop: eventLoop)
    /// }
    /// ```
    ///
    /// ## Related Types
    /// - `ConsensusNetwork` - Uses this for atomic network updates
    /// - `MirrorNetwork` - Uses this for atomic mirror network updates
    /// - `Client` - Uses this for all atomic property updates
    /// - `NetworkUpdateTask` - Uses this for periodic network updates
    ///
    /// - Parameter body: Transformation function that creates the new value from the old value
    /// - Returns: The new value that was successfully stored
    internal func readCopyUpdate(_ body: (Value) throws -> Value) rethrows -> Value {
        // Fast path: try once with weak compare-exchange
        let old = load(ordering: .acquiring)
        let new = try body(old)

        // weakCompareExchange can spuriously fail but is faster on LL/SC architectures (ARM)
        let (success, original) = weakCompareExchange(
            expected: old,
            desired: new,
            ordering: .acquiringAndReleasing
        )

        if success {
            return new
        }

        // Slow path: contention detected, use strong compare-exchange with yielding
        var current = original
        while true {
            let updated = try body(current)
            let (success, latest) = compareExchange(
                expected: current,
                desired: updated,
                ordering: .acquiringAndReleasing
            )

            if success {
                return updated
            }

            // Yield to other threads to reduce spinning and improve fairness
            sched_yield()
            current = latest
        }
    }
}
