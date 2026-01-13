// SPDX-License-Identifier: Apache-2.0

/// General-purpose extensions for Optional types.
/// These utilities are domain-agnostic and live in `common/` so they can be reused
/// across modules (e.g., parsing layers, transaction builders, etc.).
extension Optional {

    // MARK: - Assignment

    /// Assigns the wrapped value into `target` if `self` is `.some`.
    ///
    /// - Parameters:
    ///   - target: The variable or property to update when a value exists.
    func assignIfPresent(to target: inout Wrapped) {
        if let value = self { target = value }
    }

    /// Transforms the wrapped value and assigns the result into `target` if `self` is `.some`.
    ///
    /// - Parameters:
    ///   - target: The variable or property to update when a value exists.
    ///   - transform: A closure that converts the wrapped value to the target's type.
    func assignIfPresent<T>(to target: inout T, using transform: (Wrapped) -> T) {
        if let value = self { target = transform(value) }
    }

    /// Transforms the wrapped value with a throwing closure and assigns the result into `target`
    /// if `self` is `.some`.
    ///
    /// - Parameters:
    ///   - target: The variable or property to update when a value exists.
    ///   - transform: A throwing closure that converts the wrapped value to the target's type.
    /// - Throws: Rethrows any error thrown by `transform`.
    func assignIfPresent<T>(to target: inout T, using transform: (Wrapped) throws -> T) rethrows {
        if let value = self { target = try transform(value) }
    }

    // MARK: - Side Effects

    /// Performs an action with the wrapped value if `self` is `.some`.
    ///
    /// - Parameters:
    ///   - action: A closure to execute with the unwrapped value.
    func ifPresent(_ action: (Wrapped) -> Void) {
        if let value = self { action(value) }
    }

    /// Performs a throwing action with the wrapped value if `self` is `.some`.
    ///
    /// - Parameters:
    ///   - action: A throwing closure to execute with the unwrapped value.
    /// - Throws: Rethrows any error thrown by `action`.
    func ifPresent(_ action: (Wrapped) throws -> Void) rethrows {
        if let value = self { try action(value) }
    }
}
