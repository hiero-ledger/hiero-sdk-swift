// SPDX-License-Identifier: Apache-2.0

import BigInt
import Foundation
import SwiftASN1
import secp256k1

internal struct Keccak256Digest: CryptoNamespace.SecpDigest {
    internal init?(_ bytes: Data) {
        guard bytes.count == Self.byteCount else {
            return nil
        }

        self.inner = bytes
    }

    fileprivate let inner: Data
    internal static let byteCount: Int = 32

    internal func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try inner.withUnsafeBytes(body)
    }
}

public struct ChainCode {
    let data: Data
}

#if compiler(>=5.7)
    extension ChainCode: Sendable {}
#else
    extension ChainCode: @unchecked Sendable {}
#endif

/// A private key on the Hedera network.
public struct PrivateKey: LosslessStringConvertible, ExpressibleByStringLiteral, CustomStringConvertible,
    CustomDebugStringConvertible
{

    private let secp256k1Order = BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!

    /// Debug description for `PrivateKey`
    ///
    /// Please note that debugDescriptions of any kind should not be considered a stable format.
    public var debugDescription: String {
        "PrivateKey(kind: \(String(reflecting: guts)))"
    }

    // we need to be sendable, so...
    // The idea being that we initialize the key whenever we need it, which is absolutely not free, but it is `Sendable`.
    fileprivate enum Repr: CustomDebugStringConvertible {
        fileprivate var debugDescription: String {
            switch self {
            case .ed25519:
                return "ed25519([redacted])"
            case .ecdsa:
                return "ecdsa([redacted])"
            }
        }

        case ed25519(Data)
        case ecdsa(Data)

        fileprivate init(kind: PrivateKey.Kind) {
            switch kind {
            case .ecdsa(let key): self = .ecdsa(key.dataRepresentation)
            case .ed25519(let key): self = .ed25519(key.rawRepresentation)
            }
        }

        fileprivate var kind: PrivateKey.Kind {
            // swiftlint:disable force_try
            switch self {
            case .ecdsa(let key): return .ecdsa(try! .init(dataRepresentation: key))
            case .ed25519(let key): return .ed25519(try! .init(rawRepresentation: key))
            }

            // swiftlint:enable force_try
        }
    }

    fileprivate enum Kind {
        case ed25519(Ed25519PrivateKey)
        // todo use `secp256k1_bindings` directly, the key follows the requirements of `Sendable`
        // and the processing can be done more efficiently.
        case ecdsa(secp256k1.Signing.PrivateKey)
    }

    private init(kind: Kind, chainCode: Data? = nil) {
        self.guts = .init(kind: kind)
        self.chainCode = chainCode.map(ChainCode.init(data:))
    }

    private let guts: Repr

    private var kind: Kind {
        guts.kind
    }

    public let chainCode: ChainCode?

    private static func decodeBytes<S: StringProtocol>(_ description: S) throws -> Data {
        let description = description.stripPrefix("0x") ?? description[...]
        guard let bytes = Data(hexEncoded: description) else {
            throw HError(kind: .keyParse, description: "Invalid hex string")
        }

        return bytes
    }

    private init(bytes: Data) throws {
        try self.init(ed25519Bytes: bytes)
    }

    private init(ed25519Bytes bytes: Data) throws {
        guard bytes.count == 32 || bytes.count == 64 else {
            try self.init(derBytes: bytes)
            return
        }

        self.init(kind: .ed25519(try! .init(rawRepresentation: bytes.safeSubdata(in: 0..<32)!)))
    }

    private init(ecdsaBytes bytes: Data) throws {
        guard bytes.count == 32 else {
            try self.init(derBytes: bytes)
            return
        }

        do {
            self.init(kind: .ecdsa(try .init(dataRepresentation: bytes.safeSubdata(in: 0..<32)!)))
            return
        } catch {
            throw HError.keyParse(String(describing: error))
        }
    }

    private init(derBytes bytes: Data) throws {
        let info: Pkcs8.PrivateKeyInfo
        let inner: ASN1OctetString
        do {
            info = try .init(derEncoded: Array(bytes))
            // PrivateKey is an `OctetString`, and the `PrivateKey`s we all support are `OctetStrings`.
            // So, we, awkwardly, have an `OctetString` containing an `OctetString` containing our key material.
            inner = try .init(derEncoded: info.privateKey.bytes)
        } catch {
            // this is kinda painful, buuut...
            if let v = try? Self(sec1Bytes: bytes) {
                self = v
                return
            }

            throw HError.keyParse(String(describing: error))
        }

        switch info.algorithm.oid {
        case .AlgorithmIdentifier.ed25519: try self.init(ed25519Bytes: Data(inner.bytes))
        case .NamedCurves.secp256k1: try self.init(ecdsaBytes: Data(inner.bytes))
        case let oid:
            throw HError.keyParse("unsupported key algorithm: \(oid)")
        }
    }

    private init(sec1Bytes bytes: Data) throws {
        let info: Sec1.ECPrivateKey
        do {
            info = try .init(derEncoded: Array(bytes))
        } catch {
            throw HError.keyParse(String(describing: error))
        }

        switch info.parameters?.namedCurve {
        case .some(ASN1ObjectIdentifier.NamedCurves.secp256k1):
            try self.init(ecdsaBytes: Data(info.privateKey.bytes))
        case .some(let oid):
            throw HError.keyParse("unsupported key algorithm: \(oid)")
        case nil:
            throw HError.keyParse("missing curve parameters")
        }
    }

    /// Generates a new Ed25519 private key.
    public static func generateEd25519() -> Self {
        // PrivateKeyED25519.generateInternal()
        Self(kind: .ed25519(.init()), chainCode: .randomData(withLength: 32))
    }

    /// Generates a new ECDSA(secp256k1) private key.
    public static func generateEcdsa() -> Self {
        // PrivateKeyECDSA.generateInternal()
        .ecdsa(try! .init())
    }

    internal static func ed25519(_ key: Curve25519.Signing.PrivateKey) -> Self {
        let crossPlatformKey = try! Ed25519PrivateKey(rawRepresentation: key.rawRepresentation)
        return Self(kind: .ed25519(crossPlatformKey))
    }

    internal static func ecdsa(_ key: secp256k1.Signing.PrivateKey) -> Self {
        Self(kind: .ecdsa(key))
    }

    /// The ``PublicKey`` which corresponds to this private key.
    public var publicKey: PublicKey {
        switch kind {
        case .ed25519(let key): return .ed25519(key.publicKey)
        case .ecdsa(let key):
            return .ecdsa(key.publicKey)

        }
    }

    private var algorithm: Pkcs5.AlgorithmIdentifier {
        let oid: ASN1ObjectIdentifier

        switch self.guts {
        case .ed25519: oid = .AlgorithmIdentifier.ed25519
        case .ecdsa: oid = .NamedCurves.secp256k1
        }

        return .init(oid: oid)
    }

    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(bytes: bytes)
    }

    public static func fromBytesEd25519(_ bytes: Data) throws -> Self {
        try Self(ed25519Bytes: bytes)
    }

    public static func fromBytesEcdsa(_ bytes: Data) throws -> Self {
        try Self(ecdsaBytes: bytes)
    }

    public static func fromBytesDer(_ bytes: Data) throws -> Self {
        try Self(derBytes: bytes)
    }

    private init<S: StringProtocol>(parsing description: S) throws {
        try self.init(bytes: Self.decodeBytes(description))
    }

    public static func fromString<S: StringProtocol>(_ description: S) throws -> Self {
        try Self(parsing: description)
    }

    public init?(_ description: String) {
        try? self.init(parsing: description)
    }

    public init(stringLiteral value: StringLiteralType) {
        // swiftlint:disable:next force_try
        try! self.init(parsing: value)
    }

    public static func fromStringDer<S: StringProtocol>(_ description: S) throws -> Self {
        try fromBytesDer(decodeBytes(description))
    }

    public static func fromStringEd25519(_ description: String) throws -> Self {
        try fromBytesEd25519(decodeBytes(description))
    }

    public static func fromStringEcdsa(_ description: String) throws -> Self {
        try fromBytesEcdsa(decodeBytes(description))
    }

    /// Parse a `PrivateKey` from a [PEM](https://www.rfc-editor.org/rfc/rfc7468#section-10) encoded string.
    public static func fromPem(_ pem: String) throws -> Self {
        let document = try CryptoNamespace.Pem.decode(pem)

        switch document.typeLabel {
        case "PRIVATE KEY": return try fromBytesDer(document.der)
        case "EC PRIVATE KEY": return try Self(sec1Bytes: document.der)
        case let label:
            throw HError.keyParse("incorrect PEM type label: expected: `PRIVATE KEY`, got: `\(label)`")
        }
    }

    /// Parse a `PrivateKey` from a password protected [PEM](https://www.rfc-editor.org/rfc/rfc7468#section-11) encoded string.
    public static func fromPem(_ pem: String, _ password: String) throws -> Self {
        let document = try CryptoNamespace.Pem.decode(pem)

        switch document.typeLabel {
        case "ENCRYPTED PRIVATE KEY":

            guard document.headers.isEmpty else {
                throw HError.keyParse("expected pem document to have no headers")
            }

            let decrypted: Data

            do {
                let document = try Pkcs8.EncryptedPrivateKeyInfo(derEncoded: Array(document.der))
                decrypted = try document.decrypt(password: password.data(using: .utf8)!)
            } catch {
                throw HError.keyParse(String(describing: error))
            }

            return try fromBytesDer(decrypted)

        case "EC PRIVATE KEY":
            guard document.headers["Proc-Type"] == "4,ENCRYPTED" else {
                throw HError.keyParse("Encrypted EC Private Key missing or invalid `Proc-Type` header")
            }

            guard let dekInfo = document.headers["DEK-Info"] else {
                throw HError.keyParse("EC Private Key missing `DEK-Info` header")
            }

            guard let (alg, iv) = dekInfo.splitOnce(on: ",") else {
                throw HError.keyParse("Invalid `DEK-Info`")
            }

            guard let iv = Data(hexEncoded: iv) else {
                throw HError.keyParse("invalid IV: \(iv)")
            }

            let decrypted: Data

            switch alg {
            case "AES-128-CBC":
                guard iv.count == 16 else {
                    throw HError.keyParse("invalid IV")
                }

                var md5 = MD5Hasher()

                md5.update(data: password.data(using: .utf8)!)
                md5.update(data: iv[slicing: ..<8]!)

                let passphrase = Data(md5.finalize().bytes)

                do {
                    decrypted = try CryptoNamespace.Aes.aes128CbcPadDecrypt(
                        key: passphrase, iv: iv, message: document.der)
                } catch {
                    throw HError.keyParse("Failed to decrypt message: \(error)")
                }

            default:
                throw HError.keyParse("unexpected decryption alg: \(alg)")
            }

            return try Self(sec1Bytes: decrypted)
        case let label:
            throw HError.keyParse("incorrect PEM type label: expected: `PRIVATE KEY`, got: `\(label)`")
        }
    }

    public func toBytesDer() -> Data {
        let rawBytes = Array(toBytesRaw())
        let inner: [UInt8]
        do {
            var serializer = DER.Serializer()

            // swiftlint:disable:next force_try
            try! serializer.serialize(ASN1OctetString(contentBytes: rawBytes[...]))

            inner = serializer.serializedBytes
        }

        let info = Pkcs8.PrivateKeyInfo(algorithm: algorithm, privateKey: .init(contentBytes: inner[...]))

        var serializer = DER.Serializer()

        // swiftlint:disable:next force_try
        try! serializer.serialize(info)
        return Data(serializer.serializedBytes)
    }

    public func toBytes() -> Data {
        switch kind {
        case .ed25519: return toBytesRaw()
        case .ecdsa: return toBytesDer()
        }
    }

    public func toBytesRaw() -> Data {
        switch kind {
        case .ecdsa(let ecdsa): return ecdsa.dataRepresentation
        case .ed25519(let ed25519): return ed25519.rawRepresentation
        }
    }

    public var description: String {
        toStringDer()
    }

    public func toString() -> String {
        String(describing: self)
    }

    public func toStringDer() -> String {
        toBytesDer().hexStringEncoded()
    }

    public func toStringRaw() -> String {
        toBytesRaw().hexStringEncoded()
    }

    public func toAccountId(shard: UInt64, realm: UInt64) -> AccountId {
        publicKey.toAccountId(shard: shard, realm: realm)
    }

    public func isEd25519() -> Bool {
        if case .ed25519 = kind {
            return true
        }

        return false
    }

    public func isEcdsa() -> Bool {
        if case .ecdsa = kind {
            return true
        }

        return false
    }

    @Sendable
    public func sign(_ message: Data) -> Data {
        switch kind {
        case .ecdsa(let key):
            return try! key.signature(for: Keccak256Digest(CryptoNamespace.Sha3.keccak256(message))!)
                .compactRepresentation
        case .ed25519(let key):
            return try! key.signature(for: message)
        }
    }

    public func isDerivable() -> Bool {
        isEd25519() && chainCode != nil
    }

    public func derive(_ index: Int32) throws -> Self {
        let index = UInt32(bitPattern: index)

        guard let chainCode = chainCode else {
            throw HError(kind: .keyDerive, description: "key is underivable")
        }

        switch kind {
        case .ecdsa(let key):
            let isHardened = Bip32Utils.isHardenedIndex(index)
            var data = Data()
            let priv = toBytesRaw()

            if isHardened {
                data.append(0x00)
                data.append(priv)
            } else {
                data.append(key.publicKey.dataRepresentation)
            }

            // Append the index bytes
            data.append(index.bigEndianBytes)

            var hmac = HMAC<SHA512Digest>(key: SymmetricKey(data: chainCode.data))
            hmac.update(data: data)
            let hmacResult = hmac.finalize()
            let il = Data(hmacResult.prefix(32))
            let newChainCode = Data(hmacResult.suffix(32))

            let parentPrivateKeyBigInt = BigInt(priv.hexStringEncoded(), radix: 16)!
            let ilBigInt = BigInt(il.hexStringEncoded(), radix: 16)!

            // Compute child key
            let childPrivateKeyBigInt = (parentPrivateKeyBigInt + ilBigInt) % secp256k1Order

            var childPrivateKeyData = childPrivateKeyBigInt.serialize()

            // Convert to Data without leading zeros, left-pad to 32 bytes
            if childPrivateKeyData.count > 32 {
                childPrivateKeyData = childPrivateKeyData.suffix(32)
            } else if childPrivateKeyData.count < 32 {
                childPrivateKeyData = Data(repeating: 0, count: 32 - childPrivateKeyData.count) + childPrivateKeyData
            }

            // Check if private key is valid
            guard let childPrivateKey = try? secp256k1.Signing.PrivateKey(dataRepresentation: childPrivateKeyData)
            else {
                throw NSError(
                    domain: "InvalidPrivateKey", code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to initialize secp256k1 private key. Key out of range."
                    ])
            }

            return Self(
                kind: .ecdsa(try! .init(dataRepresentation: childPrivateKey.dataRepresentation)),
                chainCode: Data(newChainCode)
            )

        case .ed25519(let key):
            let index = Bip32Utils.toHardenedIndex(index)

            var hmac = HMAC<SHA512Digest>(key: SymmetricKey(data: chainCode.data))

            hmac.update(data: [0])
            hmac.update(data: key.rawRepresentation)
            hmac.update(data: index.bigEndianBytes)
            let output = hmac.finalize().bytes

            let (data, chainCode) = (output[..<32], output[32...])

            return Self(
                kind: .ed25519(try! .init(rawRepresentation: Data(data))),
                chainCode: Data(chainCode)
            )
        }
    }

    public func legacyDerive(_ index: Int64) throws -> Self {
        switch kind {
        case .ecdsa(let key):
            var seed = key.dataRepresentation

            seed.append(contentsOf: index.bigEndianBytes)

            let salt = Data([0xff])
            let derivedKey = Pkcs5.pbkdf2(
                variant: .sha2(.sha512),
                password: seed,
                salt: salt,
                rounds: 2048,
                keySize: 32
            )

            guard let newKey = try? P256.Signing.PrivateKey(rawRepresentation: derivedKey) else {
                throw KeyDerivationError.invalidDerivedKey
            }

            return try .fromBytesEcdsa(newKey.rawRepresentation)

        case .ed25519(let key):
            var seed = key.rawRepresentation

            let idx1: Int32
            switch index {
            case 0x00ff_ffff_ffff: idx1 = 0xff
            case 0...: idx1 = 0
            default: idx1 = -1
            }

            let idx2 = UInt8(truncatingIfNeeded: index)

            seed.append(idx1.bigEndianBytes)
            seed.append(Data([idx2, idx2, idx2, idx2]))

            let salt = Data([0xff])

            let key = Pkcs5.pbkdf2(variant: .sha2(.sha512), password: seed, salt: salt, rounds: 2048, keySize: 32)

            // note: this shouldn't fail, but there isn't an infaliable conversion.
            return try .fromBytesEd25519(key)
        }
    }

    // Extract the ECDSA private key from a seed.
    public static func fromSeedECDSAsecp256k1(_ seed: Data) -> Self {
        var hmac = HMAC<SHA512Digest>(key: SymmetricKey(data: "Bitcoin seed".data(using: .utf8)!))
        hmac.update(data: seed)

        let output = hmac.finalize().bytes

        let (data, chainCode) = (output[..<32], output[32...])

        // Create new private key
        let key = Self(
            kind: .ecdsa(try! .init(dataRepresentation: data)),
            chainCode: Data(chainCode)
        )

        return key
    }

    public static func fromSeedED25519(_ seed: Data) -> Self {
        var hmac = HMAC<SHA512Digest>(key: SymmetricKey(data: "ed25519 seed".data(using: .utf8)!))

        hmac.update(data: seed)

        let output = hmac.finalize().bytes

        let (data, chainCode) = (output[..<32], output[32...])

        var key = Self(
            kind: .ed25519(try! .init(rawRepresentation: Data(data))),
            chainCode: Data(chainCode)
        )

        for index: Int32 in [44, 3030, 0, 0] {
            // an error here would be... Really weird because we just set chainCode.
            // swiftlint:disable:next force_try
            key = try! key.derive(index)
        }

        return key
    }

    public static func fromMnemonic(_ mnemonic: Mnemonic, _ passphrase: String) -> Self {
        let seed = mnemonic.toSeed(passphrase: passphrase)

        var hmac = HMAC<SHA512Digest>(key: SymmetricKey(data: "ed25519 seed".data(using: .utf8)!))

        hmac.update(data: seed)

        let output = hmac.finalize().bytes

        let (data, chainCode) = (output[..<32], output[32...])

        var key = Self(
            kind: .ed25519(try! .init(rawRepresentation: Data(data))),
            chainCode: Data(chainCode)
        )

        for index: Int32 in [44, 3030, 0, 0] {
            // an error here would be... Really weird because we just set chainCode.
            // swiftlint:disable:next force_try
            key = try! key.derive(index)
        }

        return key
    }

    public static func fromMnemonic(_ mnemonic: Mnemonic) -> Self {
        Self.fromMnemonic(mnemonic, "")
    }

    public func signTransaction(_ transaction: Transaction) throws -> Data {
        try transaction.freeze()

        return transaction.addSignatureSigner(.privateKey(self))
    }
}

// for testing purposes :/
extension PrivateKey {
    internal func withChainCode(chainCode: Data) -> Self {
        precondition(chainCode.count == 32)
        return Self(kind: kind, chainCode: chainCode)
    }

    internal func prettyPrint() -> String {
        let data = toStringRaw()
        let chainCode = String(describing: chainCode?.data.hexStringEncoded())

        let start: String

        switch guts {
        case .ecdsa:
            start = "PrivateKey.ecdsa"
        case .ed25519:
            start = "PrivateKey.ed25519"
        }

        return """
            \(start)(
                key: \(data),
                chainCode: \(chainCode)
            )
            """
    }
}

extension UInt32 {
    var bigEndianBytes: Data {
        var value = self.bigEndian
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
}

extension Int64 {
    fileprivate var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian) { Array($0) }
    }
}

enum KeyDerivationError: Error {
    case invalidDerivedKey
}

#if compiler(>=5.7)
    extension PrivateKey.Repr: Sendable {}
#else
    extension PrivateKey.Repr: @unchecked Sendable {}
#endif

extension PrivateKey: Sendable {}
