// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Node Config Models

/// The TLS certificate hash data.
public struct TLSBuffer: Decodable {
    public let type: String?
    public let data: [UInt8]
}

/// The data of a new node being added.
public struct NewNode: Decodable {
    public let accountId: String
    public let name: String?
}

/// The information provided by solo upon an `add-prepare`.
public struct NodeCreateConfig: Decodable {
    public let signingCertDer: String
    public let gossipEndpoints: [String]
    public let grpcServiceEndpoints: [String]
    public let adminKey: String
    public let existingNodeAliases: [String]?
    public let tlsCertHash: TLSBuffer
    public let upgradeZipHash: String?
    public let newNode: NewNode
}

/// The information provided by solo upon an `update-prepare`.
public struct NodeUpdateConfig: Decodable {
    public let adminKey: String
    public let newAdminKey: String?
    public let freezeAdminPrivateKey: String
    public let treasuryKey: String
    public let existingNodeAliases: [String]?
    public let upgradeZipHash: String?
    public let nodeAlias: String
    public let newAccountNumber: String?
    public let tlsPublicKey: String?
    public let tlsPrivateKey: String?
    public let gossipPublicKey: String?
    public let gossipPrivateKey: String?
    public let allNodeAliases: [String]?
}

// MARK: - Helpers

/// Parse "host:port" into (host, port)
public func parseHostPort(_ s: String) throws -> (host: String, port: Int32) {
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
public func dataFromCommaSeparatedBytes(_ s: String) throws -> Data {
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
public func nilIfBlank(_ s: String?) -> String? {
    guard let s, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    return s
}

/// Parse a 0x-optional hex string into Data.
/// Accepts even/odd length; odd gets left-padded with a '0'.
public func dataFromHex(_ hexInput: String?) throws -> Data? {
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
