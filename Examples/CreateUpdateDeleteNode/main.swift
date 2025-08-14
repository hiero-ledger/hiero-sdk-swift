// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import Network
import SwiftDotenv

private struct TLSBuffer: Decodable {
    let type: String?
    let data: [UInt8]
}

private struct NewNode: Decodable {
    let accountId: String
    let name: String?
}

private struct NodeConfig: Decodable {
    let signingCertDer: String
    let gossipEndpoints: [String]
    let grpcServiceEndpoints: [String]
    let adminKey: String
    let existingNodeAliases: [String]?
    let tlsCertHash: TLSBuffer
    let upgradeZipHash: String?
    let newNode: NewNode
}

// MARK: - Helpers

/// Parse "host:port" into (host, port)
private func parseHostPort(_ s: String) throws -> (host: String, port: Int32) {
    // allow IPv6? If you need that, we can add bracketed parsing. For now mirror your JSON (IPv4/domain).
    guard let lastColon = s.lastIndex(of: ":") else {
        throw NSError(domain: "Config", code: 1, userInfo: [NSLocalizedDescriptionKey: "Endpoint '\(s)' missing :port"])
    }
    let host = String(s[..<lastColon]).trimmingCharacters(in: .whitespaces)
    let portStr = String(s[s.index(after: lastColon)...]).trimmingCharacters(in: .whitespaces)
    guard let port = Int32(portStr) else {
        throw NSError(domain: "Config", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid port in '\(s)'"])
    }
    return (host, port)
}

/// Convert a comma-separated list of decimal bytes into Data
private func dataFromCommaSeparatedBytes(_ s: String) throws -> Data {
    let parts = s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    var bytes = [UInt8]()
    bytes.reserveCapacity(parts.count)
    for part in parts where !part.isEmpty {
        guard let val = UInt8(part) else {
            throw NSError(domain: "Config", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid byte '\(part)' in signingCertDer"])
        }
        bytes.append(val)
    }
    return Data(bytes)
}

/// Build a Hiero `Endpoint` from host:port string
private func endpointFrom(_ s: String) throws -> Endpoint {
    let (host, port) = try parseHostPort(s)
    if let ip = IPv4Address(host) {
        // IP address: keep domain blank like your original
        return Endpoint(ipAddress: ip, port: port, domainName: "")
    } else {
        // Domain name
        return Endpoint(port: port, domainName: host)
    }
}

/// Load config JSON from path
private func loadConfig(at path: String) throws -> NodeConfig {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys
    return try decoder.decode(NodeConfig.self, from: data)
}

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        // Set operator account
        client.setOperator(env.operatorAccountId, env.operatorKey)
        await client.setNetworkUpdatePeriod(nanoseconds: 1_000_000_000 * 1_000_000)

        // Load config
        // let configPath = "/Users/robertwalworth/solo/context/node-add.json"
        // let cfg = try loadConfig(at: configPath)

        // // Map JSON -> SDK types
        // let accountId = try AccountId.fromString(cfg.newNode.accountId)
        // print(accountId)

        // // Endpoints
        // let gossipEndpoints: [Endpoint] = try cfg.gossipEndpoints.map(endpointFrom)
        // print(gossipEndpoints)
        // let grpcServiceEndpoints: [Endpoint] = try cfg.grpcServiceEndpoints.map(endpointFrom)
        // print(grpcServiceEndpoints)

        // // Certificates / hashes
        // let signingCertDer = try dataFromCommaSeparatedBytes(cfg.signingCertDer)
        // print(signingCertDer)
        // let tlsCertHash = Data(cfg.tlsCertHash.data)
        // print(tlsCertHash)

        // // Admin key
        // let adminKey = try PrivateKey.fromString(cfg.adminKey)
        // print(adminKey)

        // // Create the node
        // print("Creating a new node\(cfg.newNode.name.map { " named \($0)" } ?? "") from \(configPath)...")

        // let createTransaction = try NodeCreateTransaction()
        //     .accountId(accountId)
        //     .gossipEndpoints(gossipEndpoints)
        //     .serviceEndpoints(grpcServiceEndpoints)
        //     .gossipCaCertificate(signingCertDer)
        //     .grpcCertificateHash(tlsCertHash)
        //     .grpcWebProxyEndpoint(grpcServiceEndpoints[0])
        //     .adminKey(.single(adminKey.publicKey))
        //     .freezeWith(client)
        //     .sign(adminKey)

        // let response = try await createTransaction.execute(client)
        // let receipt = try await response.getReceipt(client)
        // print("Node create receipt: \(receipt)")

        // let addressBook = try await NodeAddressBookQuery().setFileId(FileId.addressBook).execute(client)
        // for nodeAddress in addressBook.nodeAddresses {
        //     print("Node ID: \(nodeAddress.nodeId)")
        //     print("Node Account ID: \(nodeAddress.nodeAccountId)")
        //     print("Node Description: \(nodeAddress.description)")
        // }

        let updateCfg = try loadNodeUpdateConfig(at: "/Users/robertwalworth/solo/context/node-update.json")
        let updateInputs = try makeNodeUpdateInputs(from: updateCfg)
        let endpoint = Endpoint(port: 50112, domainName: "network-node2-svc.solo.svc.cluster.local")

        // 2. Update the node
        print("Updating the node...")
        let updateTransaction = try NodeUpdateTransaction()
            .nodeId(1)
            .grpcWebProxyEndpoint(endpoint)
            .declineRewards(true)
            .freezeWith(client)
            .sign(updateInputs.adminKey)
        let updateTransactionResponse = try await updateTransaction.execute(client)
        let updateTransactionReceipt = try await updateTransactionResponse.getReceipt(client)
        print("Node update transaction status: \(updateTransactionReceipt.status.description)")

        // let addressBook2 = try await NodeAddressBookQuery().setFileId(FileId.addressBook).execute(client)
        // for nodeAddress in addressBook2.nodeAddresses {
        //     print("Node ID: \(nodeAddress.nodeId)")
        //     print("Node Account ID: \(nodeAddress.nodeAccountId)")
        //     print("Node Description: \(nodeAddress.description)")
        // }

        // // 3. Delete the node
        // print("Deleting the node...")
        // let deleteTransaction = try NodeDeleteTransaction()
        //     .nodeId(nodeId)
        //     .freezeWith(client)
        //     .sign(adminKey)
        // let deleteTransactionResponse = try await deleteTransaction.execute(client)
        // let deleteTransactionReceipt = try await deleteTransactionResponse.getReceipt(client)
        // print("Node delete transaction status: \(deleteTransactionReceipt.status.description)")
    }
}

extension Environment {
    /// Account ID for the operator to use in this example.
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    /// Private key for the operator to use in this example.
    internal var operatorKey: PrivateKey {
        PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
    }

    /// The name of the hedera network this example should be ran against.
    ///
    /// Testnet by default.
    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}

extension Data {
    internal init?<S: StringProtocol>(hexEncoded: S) {
        let chars = Array(hexEncoded.utf8)
        // note: hex check is done character by character
        let count = chars.count

        guard count % 2 == 0 else {
            return nil
        }

        var arr: [UInt8] = Array()
        arr.reserveCapacity(count / 2)

        for idx in stride(from: 0, to: hexEncoded.count, by: 2) {
            // swiftlint complains about the length of these if they're less than 4 characters
            // that'd be fine and all, but `low` is still only 3 characters.
            guard let highNibble = hexVal(UInt8(chars[idx])), let lowNibble = hexVal(UInt8(chars[idx + 1])) else {
                return nil
            }

            arr.append(highNibble << 4 | lowNibble)
        }

        self.init(arr)
    }
}

private func hexVal(_ char: UInt8) -> UInt8? {
    // this would be a very clean function if swift had a way of doing ascii-charcter literals, but it can't.
    let ascii0: UInt8 = 0x30
    let ascii9: UInt8 = ascii0 + 9
    let asciiUppercaseA: UInt8 = 0x41
    let asciiUppercaseF: UInt8 = 0x46
    let asciiLowercaseA: UInt8 = asciiUppercaseA | 0x20
    let asciiLowercaseF: UInt8 = asciiUppercaseF | 0x20
    switch char {
    case ascii0...ascii9:
        return char - ascii0
    case asciiUppercaseA...asciiUppercaseF:
        return char - asciiUppercaseA + 10
    case asciiLowercaseA...asciiLowercaseF:
        return char - asciiLowercaseA + 10
    default:
        return nil
    }
}

func byteStringToPEMData(_ byteString: String, label: String = "CERTIFICATE") -> Data? {
    // Step 1: Convert comma-separated decimal string to Data
    let components =
        byteString
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }

    var rawData = Data(capacity: components.count)
    for byteStr in components {
        guard let byte = UInt8(byteStr) else {
            print("Invalid byte value: \(byteStr)")
            return nil
        }
        rawData.append(byte)
    }

    // Step 2: Base64 encode the raw data
    let base64String = rawData.base64EncodedString()

    // Step 3: Split base64 string into 64-character lines
    var pemBody = ""
    var index = base64String.startIndex
    while index < base64String.endIndex {
        let nextIndex =
            base64String.index(index, offsetBy: 64, limitedBy: base64String.endIndex) ?? base64String.endIndex
        pemBody += base64String[index..<nextIndex] + "\n"
        index = nextIndex
    }

    // Step 4: Add PEM headers
    let pemString = "-----BEGIN \(label)-----\n" + pemBody + "-----END \(label)-----\n"
    return pemString.data(using: .utf8)
}

func byteStringToData(_ byteString: String) -> Data? {
    let components =
        byteString
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    var data = Data(capacity: components.count)

    for byteStr in components {
        guard let byte = UInt8(byteStr) else {
            print("Invalid byte value: \(byteStr)")
            return nil
        }
        data.append(byte)
    }

    return data
}

func byteArrayToData(_ bytes: [Int]) -> Data? {
    var data = Data(capacity: bytes.count)

    for byte in bytes {
        guard (0...255).contains(byte) else {
            print("Invalid byte value: \(byte). Must be in 0...255.")
            return nil
        }
        data.append(UInt8(byte))
    }

    return data
}

// MARK: - Update Config Models

private struct NodeUpdateConfig: Decodable {
    let adminKey: String
    let newAdminKey: String?                 // may be ""
    let freezeAdminPrivateKey: String
    let treasuryKey: String
    let existingNodeAliases: [String]?
    let upgradeZipHash: String?              // hex; may be ""
    let nodeAlias: String
    let newAccountNumber: String?            // may be "" or "123" or "0.0.123"
    let tlsPublicKey: String?                // may be ""
    let tlsPrivateKey: String?               // may be ""
    let gossipPublicKey: String?             // may be ""
    let gossipPrivateKey: String?            // may be ""
    let allNodeAliases: [String]?
}

// A convenient, typed bundle to use downstream.
private struct NodeUpdateInputs {
    let adminKey: PrivateKey
    let newAdminKey: PrivateKey?
    let freezeAdminPrivateKey: PrivateKey
    let treasuryKey: PrivateKey
    let nodeAlias: String
    let existingNodeAliases: [String]
    let allNodeAliases: [String]
    let upgradeZipHash: Data?
    let newAccountId: AccountId?
    // Keep these raw until we know format/usage
    let tlsPublicKey: String?
    let tlsPrivateKey: String?
    let gossipPublicKey: String?
    let gossipPrivateKey: String?
}

// MARK: - Generic JSON loader (reuses your style)

private func loadNodeUpdateConfig(at path: String) throws -> NodeUpdateConfig {
    // If you already added a "~" expander (resolveConfigURL), reuse it here.
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    return try decoder.decode(NodeUpdateConfig.self, from: data)
}

// MARK: - Small helpers

/// Treat nil / "" / all-whitespace as nil
@inline(__always)
private func nilIfBlank(_ s: String?) -> String? {
    guard let s, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    return s
}

/// Parse a 0x-optional hex string into Data.
/// Accepts even/odd length; odd gets left-padded with a '0'.
private func dataFromHex(_ hexInput: String?) throws -> Data? {
    guard let raw = nilIfBlank(hexInput) else { return nil }
    let hex = raw.lowercased().hasPrefix("0x") ? String(raw.dropFirst(2)) : raw
    let chars = Array(hex.filter { !$0.isWhitespace })
    guard !chars.isEmpty else { return nil }

    var bytes = [UInt8]()
    bytes.reserveCapacity((chars.count + 1) / 2)

    var idx = 0
    if chars.count % 2 != 0 {
        // odd length -> first nibble only
        guard let hi = UInt8(String(chars[0]), radix: 16) else {
            throw NSError(domain: "Config", code: 20, userInfo: [NSLocalizedDescriptionKey: "Invalid hex in upgradeZipHash"])
        }
        bytes.append(hi)
        idx = 1
    }
    while idx < chars.count {
        let hiChar = chars[idx]; let loChar = chars[idx + 1]
        guard let hi = UInt8(String(hiChar), radix: 16),
              let lo = UInt8(String(loChar), radix: 16) else {
            throw NSError(domain: "Config", code: 21, userInfo: [NSLocalizedDescriptionKey: "Invalid hex in upgradeZipHash"])
        }
        bytes.append((hi << 4) | lo)
        idx += 2
    }
    return Data(bytes)
}

/// Parse PrivateKey from a maybe-blank string.
private func parsePrivateKey(_ s: String?, field: String) throws -> PrivateKey? {
    guard let s = nilIfBlank(s) else { return nil }
    do { return try PrivateKey.fromString(s) }
    catch {
        throw NSError(domain: "Config", code: 30, userInfo: [NSLocalizedDescriptionKey: "Invalid \(field): \(error)"])
    }
}

/// Parse AccountId from either "0.0.123" or just "123".
private func parseAccountIdFlexible(_ s: String?) throws -> AccountId? {
    guard let s = nilIfBlank(s) else { return nil }
    // If it already looks like 0.0.x, defer to SDK.
    if s.contains(".") {
        return try AccountId.fromString(s)
    }
    // Otherwise treat as numeric 'num' in 0.0.num
    guard let num = UInt64(s) else {
        throw NSError(domain: "Config", code: 40, userInfo: [NSLocalizedDescriptionKey: "newAccountNumber must be a uint or '0.0.x'"])
    }
    return try AccountId.fromString("0.0.\(num)")
}

// MARK: - Map JSON -> strongly typed inputs

private func makeNodeUpdateInputs(from cfg: NodeUpdateConfig) throws -> NodeUpdateInputs {
    let adminKey = try parsePrivateKey(cfg.adminKey, field: "adminKey")!
    let newAdminKey = try parsePrivateKey(cfg.newAdminKey, field: "newAdminKey")
    let freezeAdmin = try parsePrivateKey(cfg.freezeAdminPrivateKey, field: "freezeAdminPrivateKey")!
    let treasuryKey = try parsePrivateKey(cfg.treasuryKey, field: "treasuryKey")!

    let upgradeZipHash = try dataFromHex(cfg.upgradeZipHash)
    let newAccountId = try parseAccountIdFlexible(cfg.newAccountNumber)

    return NodeUpdateInputs(
        adminKey: adminKey,
        newAdminKey: newAdminKey,
        freezeAdminPrivateKey: freezeAdmin,
        treasuryKey: treasuryKey,
        nodeAlias: cfg.nodeAlias,
        existingNodeAliases: cfg.existingNodeAliases ?? [],
        allNodeAliases: cfg.allNodeAliases ?? [],
        upgradeZipHash: upgradeZipHash,
        newAccountId: newAccountId,
        tlsPublicKey: nilIfBlank(cfg.tlsPublicKey),
        tlsPrivateKey: nilIfBlank(cfg.tlsPrivateKey),
        gossipPublicKey: nilIfBlank(cfg.gossipPublicKey),
        gossipPrivateKey: nilIfBlank(cfg.gossipPrivateKey)
    )
}