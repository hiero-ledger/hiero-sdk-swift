// SPDX-License-Identifier: Apache-2.0

/// Type aliases for swift-crypto types used throughout the SDK.
///
/// These aliases exist because some files (like `PrivateKey.swift`) cannot directly
/// import `Crypto` due to name conflicts with the secp256k1 library's `Digest` type.
/// By re-exporting these types under aliases, we avoid the ambiguity.
///
/// Available aliases:
/// - `SHA512Hash` - SHA-512 hash function
/// - `HMAC` - Hash-based Message Authentication Code
/// - `SymmetricKey` - Symmetric encryption key
/// - `Curve25519` - Ed25519 elliptic curve
/// - `P256` - secp256r1/prime256v1 elliptic curve
/// - `Insecure` - Legacy hash functions (MD5, SHA1)

import Crypto

/// SHA-512 hash function from swift-crypto.
internal typealias SHA512Hash = SHA512

/// HMAC (Hash-based Message Authentication Code) from swift-crypto.
internal typealias HMAC<H: HashFunction> = Crypto.HMAC<H>

/// Symmetric key type from swift-crypto.
internal typealias SymmetricKey = Crypto.SymmetricKey

/// Curve25519 elliptic curve from swift-crypto (used for Ed25519).
internal typealias Curve25519 = Crypto.Curve25519

/// P-256 (secp256r1/prime256v1) elliptic curve from swift-crypto.
internal typealias P256 = Crypto.P256

/// Insecure hash functions from swift-crypto (MD5, SHA1).
/// - Warning: These are cryptographically broken. Use only for legacy compatibility.
internal typealias Insecure = Crypto.Insecure
