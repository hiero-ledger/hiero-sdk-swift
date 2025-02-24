/*
 * ‌
 * Hedera Swift SDK
 *
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 *
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
 *
 */

import Foundation
import GRPC
import HieroProtobufs
import SwiftProtobuf

/// At consensus, updates an already created non-fungible token to the given values.
public final class TokenUpdateNftsTransaction: Transaction {
    /// Create a new `TokenUpdateNftsTransaction`.
    public init(
        tokenId: TokenId? = nil,
        serials: [UInt64] = [],
        metadata: Data = .init()
    ) {
        self.tokenId = tokenId
        self.serials = serials
        self.metadata = metadata

        super.init()
    }

    internal init(protobuf proto: Proto_TransactionBody, _ data: Proto_TokenUpdateNftsTransactionBody) throws {
        self.tokenId = data.hasToken ? .fromProtobuf(data.token) : nil
        self.serials = data.serialNumbers.map(UInt64.init)
        self.metadata = data.hasMetadata ? data.metadata.value : nil ?? Data.init()

        try super.init(protobuf: proto)
    }

    /// The token to be updated.
    public var tokenId: TokenId? {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the token to be updated.
    @discardableResult
    public func tokenId(_ tokenId: TokenId) -> Self {
        self.tokenId = tokenId

        return self
    }

    /// Returns the list of serial numbers to be updated.
    public var serials: [UInt64] {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the list of serial numbers to be updated.
    @discardableResult
    public func serials(_ serials: [UInt64]) -> Self {
        self.serials = serials

        return self
    }

    /// Returns the new metadata of the created token definition.
    public var metadata: Data {
        willSet {
            ensureNotFrozen()
        }
    }

    /// Sets the new metadata of the token definition.
    @discardableResult
    public func metadata(_ metadata: Data) -> Self {
        self.metadata = metadata

        return self
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try tokenId?.validateChecksums(on: ledgerId)
    }

    internal override func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        try await Proto_TokenServiceAsyncClient(channel: channel).updateToken(request)
    }

    internal override func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        _ = chunkInfo.assertSingleTransaction()

        return .tokenUpdateNfts(toProtobuf())
    }
}

extension TokenUpdateNftsTransaction: ToProtobuf {
    internal typealias Protobuf = Proto_TokenUpdateNftsTransactionBody

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            tokenId?.toProtobufInto(&proto.token)
            proto.serialNumbers = serials.map(Int64.init(bitPattern:))
            proto.metadata = Google_Protobuf_BytesValue(metadata)
        }
    }
}

extension TokenUpdateNftsTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        .tokenUpdateNfts(toProtobuf())
    }
}
