// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - FixedWidthInteger Byte Conversion
//
// Extensions for converting between integers and byte representations.
// Used for cryptographic operations, serialization, and protocol encoding.
extension FixedWidthInteger {
    // MARK: - Byte Array Initialization

    /// Initialize from little-endian byte representation.
    ///
    /// - Parameter bytes: The bytes in little-endian order (least significant byte first).
    /// - Returns: `nil` if byte count doesn't match the integer's size.
    internal init?(littleEndianBytes bytes: Data) {
        let size = MemoryLayout<Self>.size

        guard bytes.count == size else {
            return nil
        }

        self = 0
        _ = withUnsafeMutableBytes(of: &self, bytes.copyBytes(to:))
        self = littleEndian
    }

    /// Initialize from native-endian byte representation.
    ///
    /// - Parameter bytes: The bytes in platform-native byte order.
    /// - Returns: `nil` if byte count doesn't match the integer's size.
    internal init?(nativeEndianBytes bytes: Data) {
        let size = MemoryLayout<Self>.size

        guard bytes.count == size else {
            return nil
        }

        self = 0
        _ = withUnsafeMutableBytes(of: &self, bytes.copyBytes(to:))
    }

    /// Initialize from big-endian byte representation.
    ///
    /// - Parameter bytes: The bytes in big-endian order (most significant byte first).
    /// - Returns: `nil` if byte count doesn't match the integer's size.
    internal init?(bigEndianBytes bytes: Data) {
        let size = MemoryLayout<Self>.size

        guard bytes.count == size else {
            return nil
        }

        self = 0
        _ = withUnsafeMutableBytes(of: &self, bytes.copyBytes(to:))
        self = bigEndian
    }

    // MARK: - Byte Array Properties

    /// The native-endian byte representation.
    internal var nativeEndianBytes: Data {
        var num: Self = self
        return Data(bytes: &num, count: MemoryLayout.size(ofValue: num))
    }

    /// The little-endian byte representation (least significant byte first).
    internal var littleEndianBytes: Data {
        var num: Self = self.littleEndian
        return Data(bytes: &num, count: MemoryLayout.size(ofValue: num))
    }

    /// The big-endian byte representation (most significant byte first).
    internal var bigEndianBytes: Data {
        var num: Self = self.bigEndian
        return Data(bytes: &num, count: MemoryLayout.size(ofValue: num))
    }
}

// MARK: - String Parsing

extension FixedWidthInteger {
    /// Initialize by parsing a string representation.
    ///
    /// - Parameter description: The string to parse.
    /// - Throws: `HError.basicParse` if the string is not a valid number.
    internal init<S: StringProtocol>(parsing description: S) throws {
        guard let value = Self(description) else {
            throw HError.basicParse("Invalid numeric string `\(description)`")
        }

        self = value
    }
}
