// SPDX-License-Identifier: Apache-2.0

import CryptoSwift
import Foundation

// MARK: - SHA-3/Keccak Hash Functions
//
// SHA-3 and Keccak hash implementations using CryptoSwift.
//
// Note: The Hiero SDK specifically needs Keccak-256, which is the pre-standardization
// version of SHA-3 used by Ethereum and other blockchain platforms. This differs from
// the final NIST SHA-3 standard.

extension CryptoNamespace {
    /// SHA-3 and Keccak cryptographic hash functions.
    ///
    /// Currently supports:
    /// - **Keccak-256**: The pre-NIST standardization variant (used by Ethereum)
    ///
    /// Keccak-256 produces a 32-byte (256-bit) digest and is used in:
    /// - Ethereum address derivation
    /// - Ethereum transaction hashing
    /// - Smart contract function selectors
    internal enum Sha3 {
        case keccak256

        /// Compute a Keccak/SHA-3 hash of the given data.
        ///
        /// - Parameters:
        ///   - kind: The hash variant to use.
        ///   - data: The data to hash.
        /// - Returns: The hash digest as `Data`.
        @inline(__always)
        internal static func digest(_ kind: Sha3, _ data: Data) -> Data {
            kind.digest(data)
        }

        /// Compute the hash digest for this Keccak/SHA-3 variant.
        ///
        /// - Parameter data: The data to hash.
        /// - Returns: The hash digest.
        internal func digest(_ data: Data) -> Data {
            switch self {
            case .keccak256:
                return keccak256Digest(data)
            }
        }

        /// Compute a Keccak-256 hash of the given data.
        ///
        /// **Important:** This is the **pre-NIST** Keccak-256 variant used by Ethereum,
        /// not the final SHA3-256 standard. The two produce different outputs.
        ///
        /// Keccak-256 produces a 32-byte (256-bit) digest.
        ///
        /// - Parameter data: The data to hash.
        /// - Returns: The 32-byte Keccak-256 digest.
        @inline(__always)
        internal static func keccak256(_ data: Data) -> Data {
            digest(.keccak256, data)
        }

        // MARK: - Private Implementation

        /// Internal Keccak-256 implementation using CryptoSwift.
        ///
        /// - Parameter data: The data to hash.
        /// - Returns: The 32-byte Keccak-256 digest.
        private func keccak256Digest(_ data: Data) -> Data {
            // Use CryptoSwift's SHA3 engine with the Keccak variant.
            // Note: This is the pre-NIST Keccak, not the final SHA3 standard.
            let bytes = Array(data)
            // SHA3 calculate() cannot fail with valid input
            // swiftlint:disable:next force_try
            let out = try! SHA3(variant: .keccak256).calculate(for: bytes)
            return Data(out)
        }
    }
}
