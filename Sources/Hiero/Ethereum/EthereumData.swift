/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
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

import Foundation

/// Data for an ethereum transaction.
public enum EthereumData {
    /// Data for a legacy ethereum transaction.
    case legacy(Legacy)

    /// Data for an Eip 1559 ethereum transaction.
    case eip1559(Eip1559)

    internal init(rlpBytes bytes: Data) throws {
        guard let first = bytes.first else {
            throw HError.basicParse("Empty ethereum transaction data")
        }

        switch first {
        case 2: self = .eip1559(try Eip1559(rlpBytes: bytes))
        default: self = .legacy(try Legacy(rlpBytes: bytes))
        }
    }

    internal var callData: Data {
        get {
            switch self {
            case .legacy(let data): return data.callData
            case .eip1559(let data): return data.callData
            }
        }

        set(value) {
            switch self {
            case .legacy(var data):
                data.callData = value
                self = .legacy(data)
            case .eip1559(var data):
                data.callData = value
                self = .eip1559(data)
            }
        }
    }

    internal func toBytes() -> Data {
        switch self {
        case .eip1559(let data): return data.toBytes()
        case .legacy(let data): return data.toBytes()
        }
    }
}

// swiftlint:disable identifier_name
extension EthereumData {
    /// Data for a legacy ethereum transaction.
    public struct Legacy {
        /// Transaction's nonce.
        public var nonce: Data

        /// Price for 1 gas.
        public var gasPrice: Data

        /// The amount of gas available for the transaction.
        public var gasLimit: Data

        /// The receiver of the transaction.
        public var to: Data

        /// The transaction value.
        public var value: Data

        /// The raw call data.
        public var callData: Data

        /// The V value of the signature.
        public var v: Data

        /// The R value of the signature.
        public var r: Data

        /// The S value of the signature.
        public var s: Data
    }

    /// Data for an Eip 1559 ethereum transaction.
    public struct Eip1559 {
        /// ID of the chain.
        public var chainId: Data

        /// Transaction's nonce.
        public var nonce: Data

        /// An 'optional' additional fee in Ethereum that is paid directly to miners in order to incentivize
        /// them to include your transaction in a block. Not used in Hiero.
        public var maxPriorityGas: Data

        /// The maximum amount, in tinybars, that the payer of the hedera transaction
        /// is willing to pay to complete the transaction.
        public var maxGas: Data

        /// The amount of gas available for the transaction.
        public var gasLimit: Data

        /// The receiver of the transaction.
        public var to: Data

        /// The transaction value.
        public var value: Data

        /// The raw call data.
        public var callData: Data

        /// Specifies an array of addresses and storage keys that the transaction plans to access.
        public var accessList: [Data]

        /// Recovery parameter used to ease the signature verification.
        public var recoveryId: Data

        /// The R value of the signature.
        public var r: Data

        /// The S value of the signature.
        public var s: Data
    }
}
// swiftlint:enable identifier_name

extension EthereumData.Legacy: RlpDecodable, RlpEncodable {
    internal init(rlp: AnyRlp) throws {
        let expectedElements = 9

        var list = try rlp.makeRawList()

        let count = try list.count()
        guard count == expectedElements else {
            throw Rlp.DecoderError.incorrectListCount(expected: expectedElements, actual: count)
        }

        self.init(
            nonce: try list.nextValue(Data.self)!,
            gasPrice: try list.nextValue(Data.self)!,
            gasLimit: try list.nextValue(Data.self)!,
            to: try list.nextValue(Data.self)!,
            value: try list.nextValue(Data.self)!,
            callData: try list.nextValue(Data.self)!,
            v: try list.nextValue(Data.self)!,
            r: try list.nextValue(Data.self)!,
            s: try list.nextValue(Data.self)!
        )
    }

    internal func encode(to encoder: inout Rlp.Encoder) {
        encoder.append([nonce, gasPrice, gasLimit, to, value, callData, v, r, s])
    }
}

extension EthereumData.Legacy {
    internal init(rlpBytes: Data) throws {
        do {
            try self.init(rlp: AnyRlp(raw: rlpBytes))
        } catch {
            throw HError.basicParse(String(describing: error))
        }
    }

    /// Deserialize legacy ethereum data from RLP encoded bytes.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(rlpBytes: bytes)
    }

    /// Encode this legacy ethereum data to RLP encoded bytes.
    public func toBytes() -> Data {
        var encoder = Rlp.Encoder()
        encoder.append(self)
        return encoder.output
    }
}

extension EthereumData.Eip1559: RlpDecodable, RlpEncodable {
    internal init(rlp: AnyRlp) throws {
        let expectedElements = 12

        var list = try rlp.makeRawList()

        let count = try list.count()
        guard count == expectedElements else {
            throw Rlp.DecoderError.incorrectListCount(expected: expectedElements, actual: count)
        }

        self.init(
            chainId: try list.nextValue(Data.self)!,
            nonce: try list.nextValue(Data.self)!,
            maxPriorityGas: try list.nextValue(Data.self)!,
            maxGas: try list.nextValue(Data.self)!,
            gasLimit: try list.nextValue(Data.self)!,
            to: try list.nextValue(Data.self)!,
            value: try list.nextValue(Data.self)!,
            callData: try list.nextValue(Data.self)!,
            accessList: try list.nextList(Data.self)!,
            recoveryId: try list.nextValue(Data.self)!,
            r: try list.nextValue(Data.self)!,
            s: try list.nextValue(Data.self)!
        )
    }

    internal func encode(to encoder: inout Rlp.Encoder) {
        encoder.startList()

        encoder.append(chainId)
        encoder.append(nonce)
        encoder.append(maxPriorityGas)
        encoder.append(maxGas)
        encoder.append(gasLimit)
        encoder.append(to)
        encoder.append(value)
        encoder.append(callData)
        encoder.append(accessList)
        encoder.append(recoveryId)
        encoder.append(r)
        encoder.append(s)

        encoder.endList()
    }
}

extension EthereumData.Eip1559 {
    internal init(rlpBytes: Data) throws {
        guard rlpBytes.first == 2 else {
            throw HError.basicParse("Expected eip1559 transaction data to start with 0x02")
        }

        do {
            try self.init(rlp: AnyRlp(raw: rlpBytes[1...]))
        } catch {
            throw HError.basicParse(String(describing: error))
        }
    }

    /// Deserialize eip1559 ethereum data from RLP encoded bytes.
    public static func fromBytes(_ bytes: Data) throws -> Self {
        try Self(rlpBytes: bytes)
    }

    /// Encode this eip1559 ethereum data to RLP encoded bytes.
    public func toBytes() -> Data {
        var encoder = Rlp.Encoder(buffer: Data([0x02]))
        encoder.append(self)
        return encoder.output
    }
}
