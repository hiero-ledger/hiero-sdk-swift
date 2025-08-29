// SPDX-License-Identifier: Apache-2.0

///  General-purpose helpers for conditionally assigning optionals.
///  These utilities are domain-agnostic and live in `common/` so they can be reused
///  across modules (e.g., parsing layers, transaction builders, etc.).
extension Optional {

    /// Assigns the wrapped value into `target` if `self` is `.some`.
    ///
    /// - Parameters:
    ///   - target: The variable or property to update when a value exists.
    func assign(to target: inout Wrapped) {
        if let value = self { target = value }
    }

    /// Transforms the wrapped value and assigns the result into `target` if `self` is `.some`.
    ///
    /// - Parameters:
    ///   - target: The variable or property to update when a value exists.
    ///   - transform: A closure that converts the wrapped value to the target's type.
    func assign<T>(to target: inout T, using transform: (Wrapped) -> T) {
        if let value = self { target = transform(value) }
    }

    /// Transforms the wrapped value with a throwing closure and assigns the result into `target`
    /// if `self` is `.some`.
    ///
    /// - Parameters:
    ///   - target: The variable or property to update when a value exists.
    ///   - transform: A throwing closure that converts the wrapped value to the target's type.
    /// - Throws: Rethrows any error thrown by `transform`.
    func assign<T>(to target: inout T, using transform: (Wrapped) throws -> T) rethrows {
        if let value = self { target = try transform(value) }
    }
}
