/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import struct Foundation.Data
import struct HieroProtobufs.Proto_ContractNonceInfo

// Info about a contract account's nonce value.
/// The nonce for a contract is only incremented when that contract creates another contract.
public struct ContractNonceInfo: Sendable, Equatable {
    /// The contract's ID.
    public let contractId: ContractId
    /// The contract's nonce.
    public let nonce: UInt64

    /// Create a new `ContractNonceInfo` from protobuf-encoded `bytes`.
    ///
    /// # Errors
    /// - [`Error::FromProtobuf`](crate::Error::FromProtobuf) if decoding the bytes fails to produce a valid protobuf.
    /// - [`Error::FromProtobuf`](crate::Error::FromProtobuf) if decoding the protobuf fails.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(protobufBytes: bytes)
    }

    /// Convert `self` to a protobuf-encoded [`Vec<u8>`].

    public func toBytes() -> Data {
        toProtobufBytes()
    }
}

extension ContractNonceInfo: TryProtobufCodable {
    internal typealias Protobuf = Proto_ContractNonceInfo

    internal init(protobuf proto: Protobuf) throws {
        self.init(contractId: try .fromProtobuf(proto.contractID), nonce: UInt64(bitPattern: proto.nonce))
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.contractID = contractId.toProtobuf()
            proto.nonce = Int64(bitPattern: nonce)
        }
    }
}
