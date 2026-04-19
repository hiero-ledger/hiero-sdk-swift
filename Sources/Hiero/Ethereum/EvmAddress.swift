// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A 20-byte Ethereum Virtual Machine (EVM) address.
///
/// Used to identify smart contracts and Ethereum-compatible accounts on Hiero.
/// Accepts addresses with or without the `0x` prefix when parsed from a string.
public struct EvmAddress:
    CustomStringConvertible, LosslessStringConvertible, ExpressibleByStringLiteral, Hashable
{
    internal let data: Data

    internal init(_ data: Data) throws {
        guard data.count == 20 else {
            throw HError.basicParse("expected evm address to have 20 bytes, it had \(data.count)")
        }

        self.data = data
    }

    internal init<S: StringProtocol>(parsing description: S) throws {
        // Accept EVM addresses with or without the 0x prefix
        let hexString: String
        if let stripped = description.stripPrefix("0x") {
            hexString = String(stripped)
        } else {
            hexString = String(description)
        }

        guard let bytes = Data(hexEncoded: hexString) else {
            throw HError.basicParse("invalid evm address")
        }

        try self.init(bytes)
    }

    /// Creates an `EvmAddress` from a hex string, returning `nil` on failure.
    ///
    /// - Parameter description: A 40-character hex string, optionally prefixed with `0x`.
    /// - Returns: An `EvmAddress` if the string is valid hex that decodes to exactly 20 bytes, or `nil` otherwise.
    public init?(_ description: String) {
        try? self.init(parsing: description)
    }

    /// Creates an `EvmAddress` from a string literal.
    ///
    /// - Parameter value: A 40-character hex string, optionally prefixed with `0x`.
    /// - Important: This initializer will crash at runtime if the string is not valid hex
    ///   or does not decode to exactly 20 bytes. Prefer ``fromString(_:)`` for user-supplied input.
    public init(stringLiteral value: StringLiteralType) {
        // swiftlint:disable:next force_try
        try! self.init(parsing: value)
    }

    /// Creates an `EvmAddress` from a hex string, with or without the `0x` prefix.
    ///
    /// - Parameter description: A 40-character hex string, optionally prefixed with `0x`.
    /// - Throws: ``HError`` if the string is not valid hex or does not decode to exactly 20 bytes.
    public static func fromString(_ description: String) throws -> Self {
        try Self(parsing: description)
    }

    /// Creates an `EvmAddress` from raw bytes.
    ///
    /// - Parameter data: Exactly 20 bytes representing the EVM address.
    /// - Throws: ``HError`` if `data` does not contain exactly 20 bytes.
    public static func fromBytes(_ data: Data) throws -> Self {
        try Self(data)
    }

    /// The `0x`-prefixed hexadecimal string representation of this address.
    public var description: String {
        "0x\(data.hexStringEncoded())"
    }

    /// Returns the `0x`-prefixed hexadecimal string representation of this address.
    ///
    /// Equivalent to ``description``.
    public func toString() -> String {
        description
    }

    /// Returns the raw 20 bytes of this EVM address.
    public func toBytes() -> Data {
        data
    }
}

#if compiler(<5.7)
    // for some reason this wasn't `Sendable` before `5.7`
    extension EvmAddress: @unchecked Sendable {}
#else
    extension EvmAddress: Sendable {}
#endif
