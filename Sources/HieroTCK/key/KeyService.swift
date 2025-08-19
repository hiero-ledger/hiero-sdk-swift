// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

@testable import Hiero

/// Provides key generation and parsing utilities for JSON-RPC interactions.
///
/// `KeyService` supports creation of various key types including:
/// - ED25519 and ECDSA secp256k1 (public and private)
/// - Threshold keys and key lists (with recursive generation)
/// - EVM address keys derived from ECDSA
///
/// It also includes robust parsing of input key data into strongly typed Hiero `Key` representations,
/// with support for DER and protobuf formats. Used primarily in JSON-RPC method dispatching.
///
/// This is a singleton service class and should be accessed via `KeyService.service`.
internal class KeyService {

    // MARK: - Singleton

    /// Singleton instance of KeyService.
    static let service = KeyService()
    fileprivate init() {}

    // MARK: - JSON-RPC Methods

    /// Handles the `generateKey` JSON-RPC method.
    internal func generateKey(from params: GenerateKeyParams) throws -> JSONObject {
        var collectedPrivateKeys = [JSONObject]()
        let key = try generateKeyHelper(from: params, collectingPrivateKeysInto: &collectedPrivateKeys)

        var response: [String: JSONObject] = ["key": .string(key)]
        if !collectedPrivateKeys.isEmpty {
            response["privateKeys"] = .list(collectedPrivateKeys)
        }
        return .dictionary(response)
    }

    // MARK: - KeyType Enum

    /// Enum of the possible key types.
    private enum KeyType: String {
        case ecdsaSecp256k1PrivateKeyType = "ecdsaSecp256k1PrivateKey"
        case ecdsaSecp256k1PublicKeyType = "ecdsaSecp256k1PublicKey"
        case ed25519PrivateKeyType = "ed25519PrivateKey"
        case ed25519PublicKeyType = "ed25519PublicKey"
        case evmAddressKeyType = "evmAddress"
        case listKeyType = "keyList"
        case thresholdKeyType = "thresholdKey"
    }

    // MARK: - Helpers

    /// Attempts to convert a hex-encoded key string into a Hiero `Key` object.
    ///
    /// The decoding is attempted in the following order:
    /// 1. Treat the string as a DER-encoded private key and extract the public key.
    /// 2. Treat the string as a DER-encoded public key.
    /// 3. Decode the string as a protobuf-encoded `Proto_Key`.
    ///
    /// - Parameters:
    ///   - key: A hex-encoded DER or protobuf key string.
    /// - Returns: A `Key` object representing the parsed key.
    /// - Throws: `JSONError.invalidParams` if the key string is not a valid private key, public key, or Proto_Key.
    static internal func getHieroKey(from key: String) throws -> Key {
        // Attempt to parse as DER-encoded private key, extract public key
        if let privateKey = try? PrivateKey.fromStringDer(key) {
            return .single(privateKey.publicKey)
        }

        // Attempt to parse as DER-encoded public key
        if let publicKey = try? PublicKey.fromStringDer(key) {
            return .single(publicKey)
        }

        // Attempt to parse as protobuf-encoded Key
        guard let bytes = Data(hexEncoded: key) else {
            throw JSONError.invalidParams("Key string is not valid hex.")
        }

        return try Key(protobuf: Proto_Key(serializedBytes: bytes))
    }

    /// Recursively generates a serialized key string based on the `GenerateKeyParams`.
    ///
    /// This function supports nested key structures like key lists and threshold keys, and appends any generated
    /// private keys to the provided `collectedPrivateKeys` list for return to the client if needed.
    ///
    /// - Parameters:
    ///   - params: The structured input describing what kind of key to generate.
    ///   - privateKeys: A mutable list that accumulates any private keys generated in the process.
    ///   - isList: Indicates whether the key is being generated as part of a parent key list (for controlling output).
    /// - Returns: The generated key as a hex-encoded DER or protobuf string.
    /// - Throws: `JSONError.invalidParams` if input validation fails or the key cannot be generated.
    private func generateKeyHelper(
        from params: GenerateKeyParams,
        collectingPrivateKeysInto privateKeys: inout [JSONObject],
        isNestedKey: Bool = false
    ) throws -> String {
        let method: JSONRPCMethod = .generateKey

        guard let type = KeyType(rawValue: params.type) else {
            throw JSONError.invalidParams("\(method): unknown type \"\(params.type)\".")
        }

        // Validate fromKey usage
        if params.fromKey != nil,
            ![.ed25519PublicKeyType, .ecdsaSecp256k1PublicKeyType, .evmAddressKeyType].contains(type)
        {
            throw JSONError.invalidParams(
                "\(method): fromKey MUST NOT be provided for types other than ed25519PublicKey, ecdsaSecp256k1PublicKey, or evmAddress."
            )
        }

        // Validate threshold usage
        switch (params.threshold, type) {
        case (.some, .thresholdKeyType): break
        case (.some, _):
            throw JSONError.invalidParams(
                "\(method): threshold MUST NOT be provided for types other than thresholdKey.")
        case (.none, .thresholdKeyType):
            throw JSONError.invalidParams("\(method): threshold MUST be provided for thresholdKey types.")
        default: break
        }

        // Validate keys usage
        switch (params.keys, type) {
        case (.some, .listKeyType), (.some, .thresholdKeyType): break
        case (.some, _):
            throw JSONError.invalidParams(
                "\(method): keys MUST NOT be provided for types other than keyList or thresholdKey.")
        case (.none, .listKeyType), (.none, .thresholdKeyType):
            throw JSONError.invalidParams("\(method): keys MUST be provided for keyList and thresholdKey types.")
        default: break
        }

        switch type {
        case .ed25519PrivateKeyType, .ecdsaSecp256k1PrivateKeyType:
            let key = ((type == .ed25519PrivateKeyType) ? PrivateKey.generateEd25519() : PrivateKey.generateEcdsa())
                .toStringDer()

            if isNestedKey {
                privateKeys.append(.string(key))
            }

            return key

        case .ed25519PublicKeyType, .ecdsaSecp256k1PublicKeyType:
            if let fromKey = params.fromKey {
                return try PrivateKey.fromStringDer(fromKey).publicKey.toStringDer()
            }

            let key = (type == .ed25519PublicKeyType) ? PrivateKey.generateEd25519() : PrivateKey.generateEcdsa()

            if isNestedKey {
                privateKeys.append(.string(key.toStringDer()))
            }

            return key.publicKey.toStringDer()

        case .listKeyType, .thresholdKeyType:
            // It's guaranteed at this point that a list of keys is provided, so the unwrap can be safely forced.
            let hieroKeys = try params.keys!.map {
                try KeyService.getHieroKey(
                    from: generateKeyHelper(from: $0, collectingPrivateKeysInto: &privateKeys, isNestedKey: true))
            }

            var keyList = KeyList(keys: hieroKeys)

            if type == KeyType.thresholdKeyType {
                // It's guaranteed at this point that a threshold is provided, so the unwrap can be safely forced.
                keyList.threshold = Int(params.threshold!)
            }

            return Key.keyList(keyList).toProtobufBytes().hexStringEncoded()

        case .evmAddressKeyType:
            // It's guaranteed that a private ECDSA key's public key is also ECDSA, and therefore can generate an EVM address,
            // so unwraps can be safely forced.
            guard let fromKey = params.fromKey else {
                return stripHexPrefix(from: PrivateKey.generateEcdsa().publicKey.toEvmAddress()!.toString())
            }

            if let privateKey = try? PrivateKey.fromStringEcdsa(fromKey) {
                return stripHexPrefix(from: privateKey.publicKey.toEvmAddress()!.toString())
            }

            if let publicKey = try? PublicKey.fromStringEcdsa(fromKey) {
                return stripHexPrefix(from: publicKey.toEvmAddress()!.toString())
            }

            throw JSONError.invalidParams(
                "\(method): fromKey for evmAddress MUST be an ECDSAsecp256k1 private or public key.")
        }
    }

    /// Removes the leading `0x` from an EVM address if present.
    ///
    /// The Swift SDK prepends `0x` to EVM addresses, but the TCK test cases also include this prefix.
    /// This utility strips the prefix once to avoid duplication or mismatch.
    ///
    /// - Parameters:
    ///   - evmAddress: An EVM address that may or may not begin with the `0x` prefix.
    /// - Returns: The address string without the `0x` prefix.
    private func stripHexPrefix(from evmAddress: String) -> String {
        let prefix = "0x"
        return evmAddress.hasPrefix(prefix)
            ? String(evmAddress.dropFirst(prefix.count))
            : evmAddress
    }
}
