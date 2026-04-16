// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

/// A single entry within a Solidity mapping, used for indirect EVM hook storage updates.
///
/// An entry is identified by either a raw 32-byte `key` or a `preimage` whose Keccak256
/// hash forms the key. Exactly one of `key` or `preimage` should be set.
public struct EvmHookMappingEntry {
    /// The 32-byte key of the mapping entry; leading zeros may be omitted.
    ///
    /// Mutually exclusive with `preimage`.
    public var key: Data?

    /// The bytes whose Keccak256 hash forms the mapping key.
    ///
    /// Mutually exclusive with `key`.
    public var preimage: Data?

    /// The 32-byte value of the mapping entry; leading zeros may be omitted.
    ///
    /// Setting this to empty or all zeros clears the entry from the mapping.
    public var value: Data

    /// Create a new `EvmHookMappingEntry`.
    ///
    /// - Parameters:
    ///   - key: The raw 32-byte mapping key (mutually exclusive with `preimage`).
    ///   - preimage: The preimage whose hash forms the key (mutually exclusive with `key`).
    ///   - value: The 32-byte value (empty to clear the entry).
    public init(key: Data? = nil, preimage: Data? = nil, value: Data = Data()) {
        self.key = key
        self.preimage = preimage
        self.value = value
    }

    /// Sets the raw 32-byte mapping key, clearing any preimage.
    @discardableResult
    public mutating func key(_ key: Data) -> Self {
        self.key = key
        self.preimage = nil
        return self
    }

    /// Sets the preimage whose Keccak256 hash forms the mapping key, clearing any raw key.
    @discardableResult
    public mutating func preimage(_ preimage: Data) -> Self {
        self.preimage = preimage
        self.key = nil
        return self
    }

    /// Sets the 32-byte value of the mapping entry.
    ///
    /// Setting this to empty or all zeros clears the entry from the mapping.
    @discardableResult
    public mutating func value(_ value: Data) -> Self {
        self.value = value
        return self
    }
}

extension EvmHookMappingEntry: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Hapi_Node_Hooks_EvmHookMappingEntry

    internal init(protobuf proto: Protobuf) throws {
        switch proto.entryKey {
        case .key(let v):
            self.key = v
            self.preimage = nil
        case .preimage(let v):
            self.key = nil
            self.preimage = v
        case nil:
            self.key = nil
            self.preimage = nil
        }
        self.value = proto.value
    }

    internal func toProtobuf() -> Protobuf {
        var proto = Protobuf()
        if let key = key {
            proto.entryKey = .key(key)
        } else if let preimage = preimage {
            proto.entryKey = .preimage(preimage)
        }
        proto.value = value
        return proto
    }
}
