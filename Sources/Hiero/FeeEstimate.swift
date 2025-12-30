// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The fee estimate for a component. Includes the base fee and any extras.
public struct FeeEstimate: Sendable, Equatable, Hashable {
    /// The base fee price, in tinycents.
    public let base: UInt64

    /// The extra fees that apply for this fee component.
    public let extras: [FeeExtra]

    /// Create a new `FeeEstimate`.
    ///
    /// - Parameters:
    ///   - base: The base fee price, in tinycents.
    ///   - extras: The extra fees that apply for this fee component.
    public init(base: UInt64, extras: [FeeExtra]) {
        self.base = base
        self.extras = extras
    }

    /// Parse a `FeeEstimate` from a JSON dictionary.
    ///
    /// - Parameter json: The JSON dictionary containing `base` and `extras` fields.
    /// - Returns: A parsed `FeeEstimate`.
    /// - Note: Missing or malformed fields default to zero/empty values rather than throwing.
    ///   This is intentional to handle optional fields in the API response gracefully.
    internal static func fromJson(_ json: [String: Any]) throws -> FeeEstimate {
        let base = (json["base"] as? NSNumber)?.uint64Value ?? 0
        let extrasJson = json["extras"] as? [[String: Any]] ?? []
        let extras = try extrasJson.map { try FeeExtra.fromJson($0) }

        return FeeEstimate(base: base, extras: extras)
    }
}
