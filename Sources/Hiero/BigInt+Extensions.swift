// SPDX-License-Identifier: Apache-2.0

import Foundation
import NumberKit

// MARK: - BigInt Byte Conversion Extensions
//
// Extensions for converting between NumberKit's BigInt and byte representations.
// Used for cryptographic operations that require arbitrary-precision integers.

extension BigInt {
    /// Initialize a BigInt from unsigned big-endian bytes.
    ///
    /// Interprets the bytes as an unsigned integer in big-endian order
    /// (most significant byte first).
    ///
    /// - Parameter bytes: The big-endian byte representation.
    internal init(unsignedBEBytes bytes: Data) {
        self.init(0)

        for byte in bytes {
            self <<= 8
            self += Self(byte)
        }
    }

    /// Initialize a BigInt from signed big-endian bytes (two's complement).
    ///
    /// Interprets the bytes as a signed integer in big-endian order
    /// using two's complement representation.
    ///
    /// - Parameter bytes: The big-endian byte representation.
    internal init(signedBEBytes bytes: Data) {
        self.init(0)

        // Handle sign bit from first byte
        if let byte = bytes.first {
            self += Self(Int8(bitPattern: byte))
        }

        for byte in bytes.dropFirst() {
            self <<= 8
            self += Self(byte)
        }
    }

    /// Convert to big-endian byte representation.
    ///
    /// - Returns: The big-endian bytes (most significant byte first).
    internal func toBigEndianBytes() -> Data {
        Data(words.reversed().flatMap { $0.bigEndianBytes })
    }

    /// Convert to little-endian byte representation.
    ///
    /// - Returns: The little-endian bytes (least significant byte first).
    internal func toLittleEndianBytes() -> Data {
        Data(words.flatMap { $0.littleEndianBytes })
    }
}
