// SPDX-License-Identifier: Apache-2.0

/// BIP-39 mnemonic phrase implementation for the Hiero SDK.
///
/// This file provides:
/// - `Mnemonic` - BIP-39 compatible mnemonic phrases (12 or 24 words)
/// - Legacy mnemonic support (22-word format from older wallets)
///
/// Supported formats:
/// - **BIP-39 (v2/v3)**: Standard 12 or 24 word phrases
/// - **Legacy (v1)**: 22-word format from older Hedera wallets
///
/// ## Example
/// ```swift
/// // Generate a new 24-word mnemonic
/// let mnemonic = Mnemonic.generate24()
///
/// // Create a private key from the mnemonic
/// let privateKey = try mnemonic.toPrivateKey()
/// ```
///
/// Reference: [BIP-39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)

import Foundation
import NumberKit

// MARK: - Mnemonic

/// A BIP-39 mnemonic phrase for deterministic key generation.
///
/// Supports 12-word, 24-word (BIP-39), and legacy 22-word formats.
/// Use `generate12()` or `generate24()` to create new mnemonics,
/// or `fromString(_:)` / `fromWords(words:)` to parse existing ones.
public struct Mnemonic: Equatable {
    /// The internal representation of the mnemonic.
    private let kind: Kind

    /// Mnemonic format variant.
    private enum Kind: Equatable {
        /// Legacy 22-word format from older Hedera wallets.
        case v1(MnemonicV1Data)
        /// Standard BIP-39 format (12 or 24 words).
        case v2v3(MnemonicV2V3Data)
    }

    /// Creates a mnemonic with the specified kind.
    private init(kind: Mnemonic.Kind) {
        self.kind = kind
    }

    // MARK: Public Properties

    /// Returns `true` if this is a legacy 22-word mnemonic.
    ///
    /// Legacy mnemonics use a different word list and encoding scheme
    /// than standard BIP-39 mnemonics.
    public var isLegacy: Bool {
        if case .v1 = kind {
            return true
        }
        return false
    }

    /// The words that make up this mnemonic phrase.
    public var words: [String] {
        switch kind {
        case .v1(let data):
            return data.words
        case .v2v3(let data):
            return data.words
        }
    }

    // MARK: Generation

    /// Generates a new 12-word BIP-39 mnemonic (128 bits of entropy).
    ///
    /// - Returns: A randomly generated 12-word mnemonic.
    public static func generate12() -> Self {
        Self(kind: .v2v3(.generate12()))
    }

    /// Generates a new 24-word BIP-39 mnemonic (256 bits of entropy).
    ///
    /// - Returns: A randomly generated 24-word mnemonic.
    public static func generate24() -> Self {
        Self(kind: .v2v3(.generate24()))
    }

    // MARK: Parsing

    /// Parses a mnemonic from a space-separated string.
    ///
    /// - Parameter description: A space-separated list of mnemonic words.
    /// - Returns: The parsed mnemonic.
    /// - Throws: `HError.mnemonicParse` if the string is invalid.
    public static func fromString(_ description: String) throws -> Self {
        try Self(parsing: description)
    }

    /// Parses a mnemonic from an array of words.
    ///
    /// Validates the word count, word list membership, and checksum.
    ///
    /// - Parameter words: The mnemonic words (12, 22, or 24 words).
    /// - Returns: The parsed mnemonic.
    /// - Throws: `HError.mnemonicParse` if validation fails.
    public static func fromWords(words: [String]) throws -> Self {
        // Legacy 22-word format
        if words.count == 22 {
            return Self(kind: .v1(MnemonicV1Data(words: words)))
        }

        // BIP-39 format (12 or 24 words)
        let mnemonic = Self(kind: .v2v3(MnemonicV2V3Data(words: words)))

        guard words.count == 12 || words.count == 24 else {
            throw HError.mnemonicParse(.badLength(words.count), mnemonic)
        }

        // Validate words against BIP-39 word list
        var wordIndices: [UInt16] = []
        var unknownWords: [Int] = []

        for (offset, word) in words.enumerated() {
            switch bip39WordList.indexOf(word: word) {
            case .some(let index):
                wordIndices.append(UInt16(index))
            case nil:
                unknownWords.append(offset)
            }
        }

        guard unknownWords.isEmpty else {
            throw HError.mnemonicParse(.unknownWords(unknownWords), mnemonic)
        }

        // Validate checksum
        let (entropy, actualChecksum) = indicesToEntropyAndChecksum(wordIndices)

        var expectedChecksum = computeChecksum(entropy)
        expectedChecksum = words.count == 12 ? (expectedChecksum & 0xf0) : expectedChecksum

        guard expectedChecksum == actualChecksum else {
            throw HError.mnemonicParse(.checksumMismatch(expected: expectedChecksum, actual: actualChecksum), mnemonic)
        }

        return mnemonic
    }

    /// Parses a mnemonic from a space-separated string (private initializer).
    fileprivate init(parsing description: String) throws {
        self = try .fromWords(words: description.split(separator: " ").map(String.init))
    }

    // MARK: Key Derivation

    /// Derives a private key from this mnemonic using the legacy derivation method.
    ///
    /// - Returns: The derived Ed25519 private key.
    /// - Throws: `HError.mnemonicEntropy` if entropy extraction fails.
    public func toLegacyPrivateKey() throws -> PrivateKey {
        let entropy: Foundation.Data
        switch kind {
        case .v1(let mnemonic):
            entropy = try mnemonic.toEntropy()
        case .v2v3(let mnemonic):
            entropy = try mnemonic.toLegacyEntropy()
        }

        return try .fromBytes(entropy)
    }

    /// Derives a private key from this mnemonic.
    ///
    /// For BIP-39 mnemonics, uses standard BIP-39 seed derivation.
    /// For legacy mnemonics, uses the legacy entropy extraction method.
    ///
    /// - Parameter passphrase: Optional passphrase for BIP-39 derivation (not supported for legacy).
    /// - Returns: The derived Ed25519 private key.
    /// - Throws: `HError.mnemonicEntropy` if derivation fails or passphrase is used with legacy mnemonic.
    public func toPrivateKey(passphrase: String = "") throws -> PrivateKey {
        switch kind {
        case .v1 where !passphrase.isEmpty:
            throw HError.mnemonicEntropy(.legacyWithPassphrase)
        case .v1(let mnemonic):
            let entropy = try mnemonic.toEntropy()
            // swiftlint:disable:next force_try
            return try! PrivateKey.fromBytes(entropy)

        case .v2v3:
            return PrivateKey.fromMnemonic(self, "")
        }
    }

    /// Derives a standard ECDSA secp256k1 private key from this mnemonic.
    ///
    /// Uses the BIP-44 derivation path: `m/44'/3030'/0'/0/{index}`.
    ///
    /// - Parameters:
    ///   - passphrase: Optional passphrase for seed derivation.
    ///   - index: The account index in the derivation path.
    /// - Returns: The derived ECDSA secp256k1 private key.
    /// - Throws: If key derivation fails.
    public func toStandardECDSAsecp256k1PrivateKey(_ passphrase: String = "", _ index: Int32) throws -> PrivateKey {
        let seed = toSeed(passphrase: passphrase)
        var derivedKey = PrivateKey.fromSeedECDSAsecp256k1(seed)

        // BIP-44 path: m/44'/3030'/0'/0/{index}
        for pathIndex: Int32 in [
            Bip32Utils.toHardenedIndex(44),
            Bip32Utils.toHardenedIndex(3030),
            Bip32Utils.toHardenedIndex(0),
            0,
            index,
        ] {
            // swiftlint:disable:next force_try
            derivedKey = try! derivedKey.derive(pathIndex)
        }

        return derivedKey
    }

    // MARK: Serialization

    /// Returns the mnemonic as a space-separated string.
    public func toString() -> String {
        String(describing: self)
    }

    // MARK: Internal

    /// Computes the BIP-39 seed from this mnemonic.
    ///
    /// Uses PBKDF2 with HMAC-SHA512, 2048 rounds.
    ///
    /// - Parameter passphrase: Optional passphrase to include in the salt.
    /// - Returns: The 64-byte seed.
    internal func toSeed<S: StringProtocol>(passphrase: S) -> Data {
        let salt = "mnemonic" + passphrase

        return Pkcs5.pbkdf2(
            sha: .sha512,
            password: String(describing: self).data(using: .utf8)!,
            salt: salt.data(using: .utf8)!,
            rounds: 2048,
            keySize: 64
        )
    }

    /// Creates a mnemonic from raw entropy (for testing only).
    ///
    /// - Parameter entropy: The raw entropy bytes (16 or 32 bytes).
    /// - Returns: A mnemonic generated from the entropy.
    internal static func fromEntropyForTesting(entropy: Data) -> Self {
        Self(kind: .v2v3(.fromEntropy(entropy)))
    }
}

// MARK: - LosslessStringConvertible

extension Mnemonic: LosslessStringConvertible {
    /// Creates a mnemonic from a string, returning `nil` if parsing fails.
    public init?(_ description: String) {
        try? self.init(parsing: description)
    }

    /// The mnemonic as a space-separated string.
    public var description: String {
        self.words.joined(separator: " ")
    }
}

// MARK: - ExpressibleByStringLiteral

extension Mnemonic: ExpressibleByStringLiteral {
    /// The string literal type used to create a mnemonic.
    public typealias StringLiteralType = String

    /// Creates a mnemonic from a string literal.
    ///
    /// - Warning: Crashes if the string is not a valid mnemonic.
    public init(stringLiteral value: String) {
        // swiftlint:disable:next force_try
        try! self.init(parsing: value)
    }
}

// MARK: - Sendable

extension Mnemonic: Sendable {}

// MARK: - Private: MnemonicV1Data (Legacy Format)

/// Internal data structure for legacy 22-word mnemonics.
///
/// Legacy mnemonics use a 4096-word list and a different encoding scheme
/// than BIP-39. This format was used by older Hedera wallets.
private struct MnemonicV1Data: Equatable {
    /// The 22 words of the legacy mnemonic.
    let words: [String]

    /// Extracts the 32-byte entropy from the legacy mnemonic.
    ///
    /// - Returns: The extracted entropy.
    /// - Throws: `HError.mnemonicEntropy` if checksum validation fails.
    func toEntropy() throws -> Data {
        let indices: [Int32] = words.map { word in
            legacyWordList.indexOf(word: word).map(Int32.init) ?? -1
        }

        var data = Self.convertRadix(indices, from: 4096, to: 256, outputLength: 33).map(
            UInt8.init(truncatingIfNeeded:)
        )

        precondition(data.count == 33)

        let crc = data.popLast()!

        for index in 0..<data.count {
            data[index] ^= crc
        }

        let expectedCrc = Self.crc8(data)

        guard crc == expectedCrc else {
            throw HError.mnemonicEntropy(.checksumMismatch(expected: expectedCrc, actual: crc))
        }

        return Data(data)
    }

    /// Converts a number from one radix to another using BigInt arithmetic.
    ///
    /// - Parameters:
    ///   - nums: The input digits in the source radix.
    ///   - fromRadix: The source radix.
    ///   - toRadix: The target radix.
    ///   - outputLength: The expected output length.
    /// - Returns: The digits in the target radix.
    private static func convertRadix(_ nums: [Int32], from fromRadix: Int32, to toRadix: Int32, outputLength: Int)
        -> [Int32]
    {
        var buf = BigInt(0)
        let fromRadix = BigInt(fromRadix)

        for num in nums {
            buf *= fromRadix
            buf += BigInt(num)
        }

        var out: [Int32] = Array(repeating: 0, count: outputLength)
        let toRadix = BigInt(toRadix)

        for index in (0..<out.count).reversed() {
            let remainder: BigInt
            (buf, remainder) = buf.quotientAndRemainder(dividingBy: toRadix)
            out[index] = Int32(remainder.intValue!)
        }

        return out
    }

    /// Computes the CRC-8 checksum of the data.
    ///
    /// - Parameter data: The data to checksum (last byte is excluded).
    /// - Returns: The CRC-8 checksum.
    private static func crc8<C>(_ data: C) -> UInt8 where C: Collection, C.Element == UInt8 {
        var crc: UInt8 = 0xff
        for value in data.dropLast(1) {
            crc ^= value
            for _ in 0..<8 {
                crc = (crc >> 1) ^ ((crc & 1) == 0 ? 0 : 0xb2)
            }
        }

        return crc ^ 0xff
    }
}

// MARK: - Private: MnemonicV2V3Data (BIP-39 Format)

/// Internal data structure for BIP-39 mnemonics (12 or 24 words).
private struct MnemonicV2V3Data: Equatable {
    /// The words of the BIP-39 mnemonic.
    let words: [String]

    /// Generates a 12-word mnemonic from 128 bits of random entropy.
    fileprivate static func generate12() -> Self {
        fromEntropy(.randomData(withLength: 16))
    }

    /// Generates a 24-word mnemonic from 256 bits of random entropy.
    fileprivate static func generate24() -> Self {
        fromEntropy(.randomData(withLength: 32))
    }

    /// Creates a mnemonic from raw entropy.
    ///
    /// - Parameter entropyIn: The entropy bytes (16 or 32 bytes).
    /// - Returns: A mnemonic encoding the entropy.
    fileprivate static func fromEntropy(_ entropyIn: Data) -> Self {
        assert(entropyIn.count == 16 || entropyIn.count == 32, "Invalid entropy length")

        let checksumByte = computeChecksum(entropyIn)
        let entropy: Data = entropyIn + [entropyIn.count == 16 ? (checksumByte & 0xf0) : checksumByte]

        var buffer: UInt32 = 0
        var offset: UInt8 = 0
        var words: [String] = []

        for byte in entropy {
            buffer = (buffer << 8) | UInt32(byte)
            offset += 8
            if offset >= 11 {
                let index = Int(buffer >> (offset - 11) & 0x7ff)
                words.append(String(bip39WordList[index]!))
                offset -= 11
            }
        }

        return Self(words: words)
    }

    /// Extracts entropy for legacy derivation (24-word only).
    ///
    /// - Returns: The 32-byte entropy.
    /// - Throws: `HError.mnemonicEntropy` if not a 24-word mnemonic or checksum fails.
    fileprivate func toLegacyEntropy() throws -> Data {
        guard words.count == 24 else {
            throw HError.mnemonicEntropy(.badLength(expected: 24, actual: words.count))
        }

        let wordIndices = words.map { UInt16(bip39WordList.indexOf(word: $0)!) }
        let (entropy, actualChecksum) = indicesToEntropyAndChecksum(wordIndices)

        var expectedChecksum = computeChecksum(entropy)
        expectedChecksum = words.count == 12 ? (expectedChecksum & 0xf0) : expectedChecksum

        guard expectedChecksum == actualChecksum else {
            throw HError.mnemonicEntropy(.checksumMismatch(expected: expectedChecksum, actual: actualChecksum))
        }

        return entropy
    }
}

// MARK: - Private: Checksum Utilities

/// Computes the BIP-39 checksum byte from entropy.
///
/// The checksum is the first byte of SHA-256(entropy).
///
/// - Parameter data: The entropy data.
/// - Returns: The checksum byte.
private func computeChecksum(_ data: Data) -> UInt8 {
    Sha2.sha256(data)[0]
}

/// Converts BIP-39 word indices back to entropy and checksum.
///
/// - Parameter indices: The word indices (12 or 24 values, each 0-2047).
/// - Returns: A tuple of (entropy, checksum byte).
private func indicesToEntropyAndChecksum(_ indices: [UInt16]) -> (entropy: Data, checksum: UInt8) {
    precondition(indices.count == 12 || indices.count == 24)

    var output: Data = Data()
    var buf: UInt32 = 0
    var offset: UInt8 = 0

    for index in indices {
        precondition(index <= 0x7ff)

        buf = (buf << 11) | UInt32(index)
        offset += 11
        while offset >= 8 {
            let byte = UInt8(truncatingIfNeeded: buf >> (offset - 8))
            output.append(byte)
            offset -= 8
        }
    }

    if offset != 0 {
        output.append(UInt8(truncatingIfNeeded: buf << offset))
    }

    var checksum = output.popLast()!
    checksum = indices.count == 12 ? (checksum & 0xf0) : checksum

    return (output, checksum)
}
