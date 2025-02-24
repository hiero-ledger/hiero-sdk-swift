/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import Foundation

/// Common units of hbar.
///
/// For the most part they follow SI prefix conventions.
///
/// ## Hbar
/// Hbar is the native currency used by the Hedera network.
///
/// The base unit of ``Hbar`` is the ``hbar``, the following units are all expressed with values in terms of `hbar`:
///
/// | Name     | Unit         | Symbol | Value      |
/// | -------- | ------------ | ------ | ---------- |
/// | Tinybar  | ``tinybar``  | tℏ     | `1e-8`     |
/// | Microbar | ``microbar`` | µℏ     | `0.000001` |
/// | Millibar | ``millibar`` | mℏ     | `0.001`    |
/// | Hbar     | ``hbar``     | ℏ      | `1`        |
/// | Kilobar  | ``kilobar``  | kℏ     | `1000`     |
/// | Megabar  | ``megabar``  | Mℏ     | `1000000`  |
/// | Gigabar  | ``gigabar``  | Gℏ     | `1e9`      |
public enum HbarUnit: UInt64, LosslessStringConvertible, ExpressibleByStringLiteral {
    /// The Tinybar unit of Hbar.
    ///
    /// >Note: Used natively by the Hedera network.
    ///
    /// >Tip: There is a list of conversions in the type definition.
    case tinybar = 1

    /// The Microbar unit of Hbar.
    ///
    /// >Tip: There is a list of conversions in the type definition.
    case microbar = 100

    /// The Millibar unit of Hbar.
    ///
    /// >Tip: There is a list of conversions in the type definition.
    case millibar = 100_000

    /// The base unit of Hbar.
    ///
    /// >Tip: There is a list of conversions in the type definition.
    case hbar = 100_000_000

    /// The Killobar unit of Hbar.
    ///
    /// >Tip: There is a list of conversions in the type definition.
    case kilobar = 100_000_000_000

    /// The Megabar unit of Hbar.
    ///
    /// >Tip: There is a list of conversions in the type definition.
    case megabar = 100_000_000_000_000

    /// The Gigabar unit of Hbar.
    ///
    /// >Tip: There is a list of conversions in the type definition.
    case gigabar = 100_000_000_000_000_000

    /// The symbol associated with this unit of Hbar.
    public var symbol: String {
        switch self {
        case .tinybar:
            return "tℏ"
        case .microbar:
            return "µℏ"
        case .millibar:
            return "mℏ"
        case .hbar:
            return "ℏ"
        case .kilobar:
            return "kℏ"
        case .megabar:
            return "Mℏ"
        case .gigabar:
            return "Gℏ"
        }
    }

    public var description: String {
        symbol
    }

    public init(stringLiteral value: StringLiteralType) {
        try! self.init(parsing: value)
    }

    fileprivate init<S: StringProtocol>(parsing description: S) throws {
        switch description {
        case "tℏ":
            self = .tinybar
        case "µℏ":
            self = .microbar
        case "mℏ":
            self = .millibar
        case "ℏ":
            self = .hbar
        case "kℏ":
            self = .kilobar
        case "Mℏ":
            self = .megabar
        case "Gℏ":
            self = .gigabar
        default:
            throw HError.basicParse("unit must be a valid hbar unit")
        }
    }

    public init?(_ description: String) {
        try? self.init(parsing: description)
    }

    /// The value of this unit in ``tinybar``.
    public func tinybar() -> UInt64 {
        rawValue
    }
}

public struct Hbar: LosslessStringConvertible, ExpressibleByIntegerLiteral,
    ExpressibleByStringLiteral, ExpressibleByFloatLiteral, Sendable
{
    /// A constant value of zero hbars.
    public static let zero: Hbar = 0

    /// A constant value of the maximum number of hbars.
    public static let max: Hbar = 50_000_000_000

    /// A constant value of the minimum number of hbars.
    public static let min: Hbar = -50_000_000_000

    /// Create a new Hbar of the specified, possibly fractional value.
    public init(_ amount: Decimal, _ unit: HbarUnit = .hbar) throws {
        guard amount.isFinite else {
            throw HError.basicParse("amount must be a finite decimal number")
        }

        let tinybars = amount * Decimal(unit.rawValue)

        guard tinybars.isZero || (tinybars.isNormal && tinybars.exponent >= 0) else {
            throw HError.basicParse(
                "amount and unit combination results in a fractional value for tinybar, ensure tinybar value is a whole number"
            )
        }

        self.tinybars = NSDecimalNumber(decimal: tinybars).int64Value
    }

    public init(stringLiteral value: StringLiteralType) {
        // swiftlint:disable:next force_try
        try! self.init(parsing: value)
    }

    public init(integerLiteral value: IntegerLiteralType) {
        // swiftlint:disable:next force_try
        try! self.init(Decimal(value))
    }

    public init(floatLiteral value: FloatLiteralType) {
        // swiftlint:disable:next force_try
        try! self.init(Decimal(value))
    }

    public static func fromString(_ description: String) throws -> Self {
        return try Self(parsing: description)
    }

    private init<S: StringProtocol>(parsing description: S) throws {
        let (rawAmount, rawUnit) = description.splitOnce(on: " ") ?? (description[...], nil)

        let unit = try rawUnit.map { try HbarUnit(parsing: $0) } ?? .hbar

        guard let amount = Decimal(string: String(rawAmount)) else {
            throw HError.basicParse("amount not parsable as a decimal")
        }

        try self.init(amount, unit)
    }

    public init?(_ description: String) {
        try? self.init(parsing: description)
    }

    public static func from(_ amount: Decimal, _ unit: HbarUnit = .hbar) throws -> Self {
        try Self(amount, unit)
    }

    public static func fromTinybars(_ amount: Int64) -> Self {
        Self(tinybars: amount)
    }

    private init(tinybars: Int64) {
        self.tinybars = tinybars
    }

    /// The value of `self` in ``HbarUnit/tinybar``.
    public let tinybars: Int64

    /// The value of `self` in ``HbarUnit/hbar``.
    public var value: Decimal {
        value(in: .hbar)
    }

    /// Convert to a decimal value in the given `unit`.
    ///
    /// - Parameter `unit`: The unit to convert to.
    internal func value(in unit: HbarUnit) -> Decimal {
        Decimal(tinybars) / Decimal(unit.rawValue)
    }

    /// Convert to a decimal value in the given `unit`.
    ///
    /// - Parameter `unit`: The unit to convert to.
    public func to(_ unit: HbarUnit) -> Decimal {
        value(in: unit)
    }

    /// Convert this hbar value to ``HbarUnit/tinybar``.
    ///
    /// >Tip: While this function does work and is supported, ``tinybars`` is available and is preferred.
    ///
    /// - Returns: ``tinybars``
    public func toTinybars() -> Int64 {
        tinybars
    }

    public func toString(_ unit: HbarUnit? = nil) -> String {
        let unit = unit ?? (abs(tinybars) < 10_000 ? .tinybar : .hbar)

        return "\(to(unit)) \(unit)"
    }

    public var description: String {
        toString()
    }
}

extension Hbar: Equatable, Comparable {
    @inlinable
    public static func < (lhs: Hbar, rhs: Hbar) -> Bool {
        lhs.tinybars < rhs.tinybars
    }
}

extension Hbar: AdditiveArithmetic {
    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(tinybars: lhs.tinybars + rhs.tinybars)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(tinybars: lhs.tinybars - rhs.tinybars)
    }

    /// Replaces this value with its additive inverse.
    public mutating func negate() {
        self = -self
    }

    /// Returns the additive inverse the specified vaue.
    ///
    /// - Returns: The additive inverse of this value.
    public static prefix func - (operand: Self) -> Self {
        0 - operand
    }

    /// Returns the additive inverse of `self`.
    ///
    /// Returns: The additive inverse of this value.
    public func negated() -> Self {
        -self
    }
}
