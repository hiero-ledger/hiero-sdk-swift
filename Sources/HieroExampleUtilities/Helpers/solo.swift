// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

// MARK: - Node Config Models

/// The TLS certificate hash data.
public struct TLSBuffer: Decodable {
    let type: String?
    let data: [UInt8]
}

/// The data of a new node being added.
public struct NewNode: Decodable {
    let accountId: String
    let name: String?
}

/// The information provided by solo upon an `add-prepare`.
public struct NodeCreateConfig: Decodable {
    let signingCertDer: String
    let gossipEndpoints: [String]
    let grpcServiceEndpoints: [String]
    let adminKey: String
    let existingNodeAliases: [String]?
    let tlsCertHash: TLSBuffer
    let upgradeZipHash: String?
    let newNode: NewNode
}

/// The information provided by solo upon an `update-prepare`.
public struct NodeUpdateConfig: Decodable {
    let adminKey: String
    let newAdminKey: String?
    let freezeAdminPrivateKey: String
    let treasuryKey: String
    let existingNodeAliases: [String]?
    let upgradeZipHash: String?
    let nodeAlias: String
    let newAccountNumber: String?
    let tlsPublicKey: String?
    let tlsPrivateKey: String?
    let gossipPublicKey: String?
    let gossipPrivateKey: String?
    let allNodeAliases: [String]?
}

// A convenient, typed bundle to use downstream.
public struct NodeUpdateInputs {
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
            throw NSError(
                domain: "Config", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid byte '\(part)' in signingCertDer"])
        }
        bytes.append(val)
    }
    return Data(bytes)
}

/// Build a Hiero `Endpoint` from host:port string
private func endpointFrom(_ s: String) throws -> Endpoint {
    let (host, port) = try parseHostPort(s)
    guard let ip = IPv4Address(host) else {
        // Domain name
        return Endpoint(port: port, domainName: host)
    }
    // IP address: keep domain blank like your original
    return Endpoint(ipAddress: ip, port: port, domainName: "")
}

/// Load config JSON from path
public func loadNodeCreateConfig(at path: String) throws -> NodeCreateConfig {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys
    return try decoder.decode(NodeCreateConfig.self, from: data)
}

// MARK: - Generic JSON loader (reuses your style)

public func loadNodeUpdateConfig(at path: String) throws -> NodeUpdateConfig {
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
            throw NSError(
                domain: "Config", code: 20, userInfo: [NSLocalizedDescriptionKey: "Invalid hex in upgradeZipHash"])
        }
        bytes.append(hi)
        idx = 1
    }
    while idx < chars.count {
        let hiChar = chars[idx]
        let loChar = chars[idx + 1]
        guard let hi = UInt8(String(hiChar), radix: 16),
            let lo = UInt8(String(loChar), radix: 16)
        else {
            throw NSError(
                domain: "Config", code: 21, userInfo: [NSLocalizedDescriptionKey: "Invalid hex in upgradeZipHash"])
        }
        bytes.append((hi << 4) | lo)
        idx += 2
    }
    return Data(bytes)
}

/// Parse PrivateKey from a maybe-blank string.
private func parsePrivateKey(_ s: String?, field: String) throws -> PrivateKey? {
    guard let s = nilIfBlank(s) else { return nil }
    do { return try PrivateKey.fromString(s) } catch {
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
        throw NSError(
            domain: "Config", code: 40,
            userInfo: [NSLocalizedDescriptionKey: "newAccountNumber must be a uint or '0.0.x'"])
    }
    return try AccountId.fromString("0.0.\(num)")
}

// MARK: - Map JSON -> strongly typed inputs

public func makeNodeUpdateInputs(from cfg: NodeUpdateConfig) throws -> NodeUpdateInputs {
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
