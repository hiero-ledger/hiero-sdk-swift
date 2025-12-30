// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The extra fee charged for the transaction.
public struct FeeExtra: Sendable, Equatable, Hashable {
    /// The unique name of this extra fee as defined in the fee schedule.
    public let name: String

    /// The count of this "extra" that is included for free.
    public let included: UInt32

    /// The actual count of items received.
    public let count: UInt32

    /// The charged count of items as calculated by max(0, count - included).
    public let charged: UInt32

    /// The fee price per unit in tinycents.
    public let feePerUnit: UInt64

    /// The subtotal in tinycents for this extra fee. Calculated by multiplying the
    /// charged count by the feePerUnit.
    public let subtotal: UInt64

    /// Create a new `FeeExtra`.
    ///
    /// - Parameters:
    ///   - name: The unique name of this extra fee as defined in the fee schedule.
    ///   - included: The count of this "extra" that is included for free.
    ///   - count: The actual count of items received.
    ///   - charged: The charged count of items as calculated by max(0, count - included).
    ///   - feePerUnit: The fee price per unit in tinycents.
    ///   - subtotal: The subtotal in tinycents for this extra fee.
    public init(
        name: String,
        included: UInt32,
        count: UInt32,
        charged: UInt32,
        feePerUnit: UInt64,
        subtotal: UInt64
    ) {
        self.name = name
        self.included = included
        self.count = count
        self.charged = charged
        self.feePerUnit = feePerUnit
        self.subtotal = subtotal
    }

    /// Parse a `FeeExtra` from a JSON dictionary.
    ///
    /// - Parameter json: The JSON dictionary containing fee extra fields.
    /// - Returns: A parsed `FeeExtra`.
    /// - Note: Missing or malformed fields default to zero/empty values rather than throwing.
    ///   This is intentional to handle optional fields in the API response gracefully.
    ///   The `fee_per_unit` JSON key maps to the `feePerUnit` property.
    internal static func fromJson(_ json: [String: Any]) throws -> FeeExtra {
        let name = json["name"] as? String ?? ""
        let included = (json["included"] as? NSNumber)?.uint32Value ?? 0
        let count = (json["count"] as? NSNumber)?.uint32Value ?? 0
        let charged = (json["charged"] as? NSNumber)?.uint32Value ?? 0
        let feePerUnit = (json["fee_per_unit"] as? NSNumber)?.uint64Value ?? 0
        let subtotal = (json["subtotal"] as? NSNumber)?.uint64Value ?? 0

        return FeeExtra(
            name: name,
            included: included,
            count: count,
            charged: charged,
            feePerUnit: feePerUnit,
            subtotal: subtotal
        )
    }
}
