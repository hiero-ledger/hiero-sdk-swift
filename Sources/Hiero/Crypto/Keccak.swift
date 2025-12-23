// SPDX-License-Identifier: Apache-2.0

/// Keccak cryptographic hash functions and related types.
///
/// This file provides:
/// - `Keccak` - Keccak-256 hash function
/// - `Keccak256Digest` - Wrapper for secp256k1 signing compatibility
///
/// **Note:** Keccak-256 is the pre-NIST standardization version used by Ethereum
/// and other blockchain platforms. This differs from the final NIST SHA-3 standard
/// (they produce different outputs for the same input).
///
/// ## Example
/// ```swift
/// // Compute a hash
/// let hash = Keccak.keccak256(data)
///
/// // Use with secp256k1 signing
/// guard let digest = Keccak256Digest(hash) else { ... }
/// let signature = try key.signature(for: digest)
/// ```

import Foundation
import secp256k1

import class CryptoSwift.SHA3

// MARK: - Keccak Hash Functions

/// Keccak cryptographic hash functions.
///
/// Currently supports:
/// - **Keccak-256**: 256-bit (32-byte) output
///
/// Used for:
/// - Ethereum address derivation
/// - ECDSA message signing
/// - Smart contract function selectors
internal enum Keccak {
    case keccak256

    /// Compute a Keccak hash of the given data.
    ///
    /// - Parameters:
    ///   - kind: The hash variant to use.
    ///   - data: The data to hash.
    /// - Returns: The hash digest as `Data`.
    @inline(__always)
    internal static func digest(_ kind: Keccak, _ data: Data) -> Data {
        kind.digest(data)
    }

    /// Compute the hash digest for this Keccak variant.
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
    /// Keccak-256 produces a 32-byte (256-bit) digest.
    ///
    /// - Parameter data: The data to hash.
    /// - Returns: The 32-byte Keccak-256 digest.
    @inline(__always)
    internal static func keccak256(_ data: Data) -> Data {
        digest(.keccak256, data)
    }

    // MARK: Private Implementation

    private func keccak256Digest(_ data: Data) -> Data {
        let bytes = Array(data)
        // swiftlint:disable:next force_try
        let out = try! SHA3(variant: .keccak256).calculate(for: bytes)
        return Data(out)
    }
}

// MARK: - Keccak256Digest (secp256k1 Adapter)

/// Keccak-256 digest wrapper for secp256k1 signing.
///
/// This adapter enables using Keccak-256 hashes with secp256k1 signing and verification,
/// which is required for Ethereum-compatible ECDSA signatures (used by Hedera ECDSA keys).
///
/// The secp256k1 library expects a `Digest` type for signing, but `Keccak.keccak256()`
/// returns raw `Data`. This wrapper bridges the two by implementing the required protocol.
///
/// ## Example
/// ```swift
/// let hash = Keccak.keccak256(message)
/// guard let digest = Keccak256Digest(hash) else { ... }
/// let signature = try key.signature(for: digest)
/// ```
internal struct Keccak256Digest: Hashable, Digest {
    /// The underlying hash bytes.
    fileprivate let inner: Data

    /// The expected byte count for Keccak-256 (32 bytes / 256 bits).
    internal static let byteCount: Int = 32

    /// Create a digest from raw hash bytes.
    ///
    /// - Parameter bytes: The 32-byte Keccak-256 hash.
    /// - Returns: `nil` if bytes is not exactly 32 bytes.
    internal init?(_ bytes: Data) {
        guard bytes.count == Self.byteCount else {
            return nil
        }
        self.inner = bytes
    }

    // MARK: ContiguousBytes

    /// Access the raw bytes of the digest.
    ///
    /// - Parameter body: Closure that receives an `UnsafeRawBufferPointer` to the bytes.
    /// - Returns: The value returned by the closure.
    internal func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try inner.withUnsafeBytes(body)
    }

    // MARK: Sequence

    /// Returns an iterator over the bytes of the digest.
    internal func makeIterator() -> Data.Iterator {
        inner.makeIterator()
    }

    // MARK: CustomStringConvertible

    /// A hexadecimal string representation of the digest.
    internal var description: String {
        inner.hexStringEncoded()
    }
}
