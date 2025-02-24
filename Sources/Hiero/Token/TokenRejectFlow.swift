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

public final class TokenRejectFlow {
    fileprivate var nodeAccountIds: [AccountId]?

    internal struct TokenRejectTransactionData {
        internal init(
            ownerId: AccountId? = nil,
            tokenIds: [TokenId] = [],
            nftIds: [NftId] = [],
            freezeWithClient: Client? = nil,
            signPrivateKey: PrivateKey? = nil,
            signPublicKey: PublicKey? = nil,
            signer: Signer? = nil
        ) {
            self.ownerId = ownerId
            self.tokenIds = tokenIds
            self.nftIds = nftIds
            self.freezeWithClient = freezeWithClient
            self.signPrivateKey = signPrivateKey
            self.signPublicKey = signPublicKey
            self.signer = signer
        }
        fileprivate var ownerId: AccountId?

        fileprivate var tokenIds: [TokenId]

        fileprivate var nftIds: [NftId]

        fileprivate var freezeWithClient: Client?

        fileprivate var signPrivateKey: PrivateKey?

        fileprivate var signPublicKey: PublicKey?

        fileprivate var signer: Signer?
    }

    public init() {
        self.nodeAccountIds = nil
        self.tokenRejectData = .init()
    }

    private var tokenRejectData: TokenRejectTransactionData

    /// Assign the Account ID of the Owner.
    @discardableResult
    public func ownerId(_ accountId: AccountId) throws -> Self {
        self.tokenRejectData.ownerId = accountId

        return self
    }

    /// Assign a list of TokenIds
    @discardableResult
    public func tokenIds(_ tokenIds: [TokenId]) throws -> Self {
        self.tokenRejectData.tokenIds = tokenIds

        return self
    }

    /// Append a Token ID to the list of Ids for rejection
    @discardableResult
    public func addTokenId(_ tokenId: TokenId) throws -> Self {
        self.tokenRejectData.tokenIds.append(tokenId)

        return self
    }

    /// Assign a list of Nft IDs
    @discardableResult
    public func nftIds(_ nftIds: [NftId]) throws -> Self {
        self.tokenRejectData.nftIds = nftIds

        return self
    }

    /// Append an Nft ID to the list of Ids for rejection
    @discardableResult
    public func addNftId(_ nftId: NftId) throws -> Self {
        self.tokenRejectData.nftIds.append(nftId)

        return self
    }

    /// Set the account IDs of the nodes that this transaction will be submitted to.
    @discardableResult
    public func nodeAccountIds(_ nodeAccountIds: [AccountId]) throws -> Self {
        self.nodeAccountIds = nodeAccountIds

        return self
    }

    /// Sets the client to use for freezing the generated *``TokenRejectTransaction``*.
    @discardableResult
    public func freezeWith(_ client: Client) throws -> Self {
        self.tokenRejectData.freezeWithClient = client

        return self
    }

    /// Set the private key that this transaction will be signed with.
    ///
    /// >Important: Only *one* signer is allowed.
    @discardableResult
    public func sign(_ privateKey: PrivateKey) throws -> Self {
        self.tokenRejectData.signer = .privateKey(privateKey)

        return self
    }

    /// Set the private key that this transaction will be signed with.
    @discardableResult
    public func signWith(_ publicKey: PublicKey, _ signer: @Sendable @escaping (Data) -> (Data)) throws -> Self {
        self.tokenRejectData.signer = .init(publicKey, signer)

        return self
    }

    /// Set the operator that this transaction will be signed with.
    @discardableResult
    public func signWithOperator(_ client: Client) throws -> Self {
        let operatorKey = client.operator?.signer
        guard let operatorKey = operatorKey else {
            fatalError("Must call `Client.setOperator` to use token reject flow")
        }
        self.tokenRejectData.signer = operatorKey

        return self
    }

    public func execute(_ client: Client) async throws -> TransactionResponse {
        try await Self.executeWithOptionalTimeout(
            client, timeoutPerTransaction: nil, nodeAccountIds: self.nodeAccountIds,
            tokenRejectData: self.tokenRejectData)

    }

    public func executeWithTimeout(_ client: Client, _ timeoutPerTransaction: TimeInterval) async throws
        -> TransactionResponse
    {
        try await Self.executeWithOptionalTimeout(
            client, timeoutPerTransaction: timeoutPerTransaction, nodeAccountIds: self.nodeAccountIds,
            tokenRejectData: self.tokenRejectData)
    }

    private static func executeWithOptionalTimeout(
        _ client: Client, timeoutPerTransaction: TimeInterval?, nodeAccountIds: [AccountId]?,
        tokenRejectData: TokenRejectTransactionData
    ) async throws -> TransactionResponse {
        let rejectResponse = try await makeTokenRejectTransaction(nodeAccountIds, tokenRejectData: tokenRejectData)
            .execute(client, timeoutPerTransaction)

        _ = try await rejectResponse.getReceiptQuery().execute(client, timeoutPerTransaction)

        let dissociateResponse = try await makeTokenDissociateTransaction(
            nodeAccountIds, tokenRejectData: tokenRejectData
        ).execute(client, timeoutPerTransaction)

        _ = try await dissociateResponse.getReceiptQuery().execute(client, timeoutPerTransaction)

        return rejectResponse
    }

    static func makeTokenRejectTransaction(
        _ nodeAccountIds: [AccountId]?,
        tokenRejectData data: TokenRejectTransactionData
    ) throws -> TokenRejectTransaction {
        let tmp = TokenRejectTransaction()

        if let ownerId = data.ownerId {
            tmp.owner(ownerId)
        }

        tmp.tokenIds(data.tokenIds)

        tmp.nftIds(data.nftIds)

        if let nodeAccountIds = nodeAccountIds {
            tmp.nodeAccountIds(nodeAccountIds)
        }

        if let freezeWithClient = data.freezeWithClient {
            try tmp.freezeWith(freezeWithClient)
        }

        if let signer = data.signer {
            tmp.signWithSigner(signer)
        }

        return tmp
    }

    private static func makeTokenDissociateTransaction(
        _ nodeAccountIds: [AccountId]?,
        tokenRejectData data: TokenRejectTransactionData
    ) throws -> TokenDissociateTransaction {

        var tokenIds = data.tokenIds
        tokenIds.append(contentsOf: data.nftIds.map { $0.tokenId })

        let uniqueTokenIds = Array(Set(tokenIds))

        let tmp = TokenDissociateTransaction()

        if let ownerId = data.ownerId {
            tmp.accountId(ownerId)
        }

        tmp.tokenIds(uniqueTokenIds)

        if let nodeAccountIds = nodeAccountIds {
            tmp.nodeAccountIds(nodeAccountIds)
        }

        if let freezeWithClient = data.freezeWithClient {
            try tmp.freezeWith(freezeWithClient)
        }

        if let signer = data.signer {
            tmp.signWithSigner(signer)
        }

        return tmp
    }
}
