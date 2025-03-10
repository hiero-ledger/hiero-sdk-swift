// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct LedgerId: LosslessStringConvertible, ExpressibleByStringLiteral, Equatable,
    CustomStringConvertible
{
    public static let mainnet = LedgerId(Data([0]))

    public static let testnet = LedgerId(Data([1]))

    public static let previewnet = LedgerId(Data([2]))

    public static func fromBytes(_ bytes: Data) -> Self {
        Self(bytes)
    }

    public static func fromString(_ description: String) -> Self? {
        Self(description)
    }

    public init(_ bytes: Data) {
        self.bytes = bytes
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)!
    }

    public init?(_ description: String) {
        switch description {
        case "mainnet":
            self = .mainnet
            return
        case "testnet":
            self = .testnet
            return
        case "previewnet":
            self = .previewnet
            return
        default:
            guard let bytes = Data(hexEncoded: description) else {
                return nil
            }

            self.bytes = bytes
        }
    }

    internal let bytes: Data

    public func isMainnet() -> Bool {
        self == .mainnet
    }

    public func isTestnet() -> Bool {
        self == .testnet
    }

    public func isPreviewnet() -> Bool {
        self == .previewnet
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes == rhs.bytes
    }

    public var description: String {
        if isMainnet() {
            return "mainnet"
        }

        if isTestnet() {
            return "testnet"
        }

        if isPreviewnet() {
            return "previewnet"
        }

        return bytes.hexStringEncoded()
    }

    public func toString() -> String {
        description
    }
}

#if compiler(<5.7)
    // Swift 5.7 added the conformance to data, despite to the best of my knowledge, not changing anything in the underlying type.
    extension LedgerId: @unchecked Sendable {}
#else
    extension LedgerId: Sendable {}
#endif
