// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

@testable import Hiero

/// Service class that services key requests.
internal class KeyService {

    /// Singleton instance of KeyService.
    static let service = KeyService()

    ////////////////
    /// INTERNAL ///
    ////////////////

    /// Generate a key. Can be called via JSON-RPC.
    internal func generateKey(_ params: GenerateKeyParams) throws -> JSONObject {
        var privateKeys = [JSONObject]()
        let key = try generateKeyHelper(params, &privateKeys)

        return JSONObject.dictionary(
            privateKeys.isEmpty
                ? ["key": JSONObject.string(key)]
                : ["key": JSONObject.string(key), "privateKeys": JSONObject.list(privateKeys)])
    }

    /// Get a Hiero Key object from a hex-encoded key string.
    internal func getHieroKey(_ key: String) throws -> Key {
        do {
            return Key.single(try PrivateKey.fromStringDer(key).publicKey)
        } catch {
            do {
                return Key.single(try PublicKey.fromStringDer(key))
            } catch {
                return try Key(protobuf: try Proto_Key(serializedBytes: Data(hexEncoded: key) ?? Data()))
            }
        }
    }

    ///////////////
    /// PRIVATE ///
    ///////////////

    /// Enum of the possible key types.
    private enum KeyType: String {
        case ed25519PrivateKeyType = "ed25519PrivateKey"
        case ed25519PublicKeyType = "ed25519PublicKey"
        case ecdsaSecp256k1PrivateKeyType = "ecdsaSecp256k1PrivateKey"
        case ecdsaSecp256k1PublicKeyType = "ecdsaSecp256k1PublicKey"
        case listKeyType = "keyList"
        case thresholdKeyType = "thresholdKey"
        case evmAddressKeyType = "evmAddress"
    }

    /// Helper function used to generate keys that can be called recursively (useful when generating a KeyList, for example).
    private func generateKeyHelper(
        _ params: GenerateKeyParams, _ privateKeys: inout [JSONObject], _ isList: Bool = false
    ) throws -> String {
        guard let type = KeyType(rawValue: params.type) else {
            throw JSONError.invalidParams("\(JSONRPCMethod.generateKey): type is NOT a valid value.")
        }

        if params.fromKey != nil, type != .ed25519PublicKeyType, type != .ecdsaSecp256k1PublicKeyType,
            type != .evmAddressKeyType
        {
            throw JSONError.invalidParams(
                "\(JSONRPCMethod.generateKey): fromKey MUST NOT be provided for types other than ed25519PublicKey, ecdsaSecp256k1PublicKey, or evmAddress."
            )
        }

        if params.threshold != nil, type != .thresholdKeyType {
            throw JSONError.invalidParams(
                "\(JSONRPCMethod.generateKey): threshold MUST NOT be provided for types other than thresholdKey.")
        } else if params.threshold == nil, type == .thresholdKeyType {
            throw JSONError.invalidParams(
                "\(JSONRPCMethod.generateKey): threshold MUST be provided for thresholdKey types.")
        }

        if params.keys != nil, type != .listKeyType, type != .thresholdKeyType {
            throw JSONError.invalidParams(
                "\(JSONRPCMethod.generateKey): keys MUST NOT be provided for types other than keyList or thresholdKey."
            )
        } else if params.keys == nil, type == .listKeyType || type == .thresholdKeyType {
            throw JSONError.invalidParams(
                "\(JSONRPCMethod.generateKey): keys MUST be provided for keyList and thresholdKey types.")
        }

        switch type {
        case .ed25519PrivateKeyType, .ecdsaSecp256k1PrivateKeyType:
            let key = ((type == .ed25519PrivateKeyType) ? PrivateKey.generateEd25519() : PrivateKey.generateEcdsa())
                .toStringDer()

            if isList {
                privateKeys.append(JSONObject.string(key))
            }

            return key

        case .ed25519PublicKeyType, .ecdsaSecp256k1PublicKeyType:
            if let fromKey = params.fromKey {
                return try PrivateKey.fromStringDer(fromKey).publicKey.toStringDer()
            }

            let key = (type == .ed25519PublicKeyType) ? PrivateKey.generateEd25519() : PrivateKey.generateEcdsa()

            if isList {
                privateKeys.append(JSONObject.string(key.toStringDer()))
            }

            return key.publicKey.toStringDer()

        case .listKeyType, .thresholdKeyType:
            /// It's guaranteed at this point that a list of keys is provided, so the unwrap can be safely forced.
            var keyList = KeyList(
                keys: try params.keys!.map { try getHieroKey(generateKeyHelper($0, &privateKeys, true)) })

            if type == KeyType.thresholdKeyType {
                /// It's guaranteed at this point that a threshold is provided, so the unwrap can be safely forced.
                keyList.threshold = Int(params.threshold!)
            }

            return Key.keyList(keyList).toProtobufBytes().hexStringEncoded()

        case .evmAddressKeyType:
            guard let fromKey = params.fromKey else {
                return PrivateKey.generateEcdsa().publicKey.toEvmAddress()!.toString()
            }

            do {
                return try PrivateKey.fromStringEcdsa(fromKey).publicKey.toEvmAddress()!.toString()
            } catch {
                do {
                    return try PublicKey.fromStringEcdsa(fromKey).toEvmAddress()!.toString()
                } catch {
                    throw JSONError.invalidParams(
                        "\(JSONRPCMethod.generateKey): fromKey for evmAddress MUST be an ECDSAsecp256k1 private or public key."
                    )
                }
            }
        }
    }
}
