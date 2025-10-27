// SPDX-License-Identifier: Apache-2.0

// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs
import SwiftProtobuf

public class AbstractTokenTransferTransaction: Transaction {
    // avoid scope collisions by nesting :/
    struct Transfer: ValidateChecksums {
        let accountId: AccountId
        var amount: Int64
        let isApproval: Bool
        var preTxAllowanceHook: HookCall?
        var prePostTxAllowanceHook: HookCall?

        internal func validateChecksums(on ledgerId: LedgerId) throws {
            try accountId.validateChecksums(on: ledgerId)
            try preTxAllowanceHook?.validateChecksums(on: ledgerId)
            try prePostTxAllowanceHook?.validateChecksums(on: ledgerId)
        }
    }

    struct TokenTransfer: ValidateChecksums {
        let tokenId: TokenId
        var transfers: [AbstractTokenTransferTransaction.Transfer]
        var nftTransfers: [AbstractTokenTransferTransaction.NftTransfer]
        var expectedDecimals: UInt32?

        internal func validateChecksums(on ledgerId: LedgerId) throws {
            try tokenId.validateChecksums(on: ledgerId)
            try transfers.validateChecksums(on: ledgerId)
            try nftTransfers.validateChecksums(on: ledgerId)
        }
    }

    struct NftTransfer: ValidateChecksums {
        let senderAccountId: AccountId
        let receiverAccountId: AccountId
        let serial: UInt64
        let isApproval: Bool
        var preTxSenderAllowanceHook: HookCall?
        var prePostTxSenderAllowanceHook: HookCall?
        var preTxReceiverAllowanceHook: HookCall?
        var prePostTxReceiverAllowanceHook: HookCall?

        internal func validateChecksums(on ledgerId: LedgerId) throws {
            try senderAccountId.validateChecksums(on: ledgerId)
            try receiverAccountId.validateChecksums(on: ledgerId)
            try preTxSenderAllowanceHook?.validateChecksums(on: ledgerId)
            try prePostTxSenderAllowanceHook?.validateChecksums(on: ledgerId)
            try preTxReceiverAllowanceHook?.validateChecksums(on: ledgerId)
            try prePostTxReceiverAllowanceHook?.validateChecksums(on: ledgerId)
        }
    }

    var transfers: [AbstractTokenTransferTransaction.Transfer] = [] {
        willSet {
            ensureNotFrozen(fieldName: "transfers")
        }
    }

    public var tokenTransfers: [TokenId: [AccountId: Int64]] {
        Dictionary(
            tokenTransfersInner.lazy.map { item in
                (
                    item.tokenId,
                    Dictionary(
                        item.transfers.lazy.map { ($0.accountId, $0.amount) },
                        uniquingKeysWith: { first, _ in first }
                    )
                )
            },
            uniquingKeysWith: { (first, _) in first }
        )
    }

    public var tokenNftTransfers: [TokenId: [TokenNftTransfer]] {
        Dictionary(
            tokenTransfersInner.lazy.map { item in
                (
                    item.tokenId,
                    item.nftTransfers.map {
                        TokenNftTransfer(
                            tokenId: item.tokenId,
                            sender: $0.senderAccountId,
                            receiver: $0.receiverAccountId,
                            serial: $0.serial,
                            isApproved: $0.isApproval
                        )
                    }
                )
            },
            uniquingKeysWith: { (first, _) in first }
        )
    }

    internal var tokenTransfersInner: [AbstractTokenTransferTransaction.TokenTransfer] = [] {
        willSet {
            ensureNotFrozen(fieldName: "tokenTransfers")
        }
    }

    /// Extract the list of token id decimals.
    public var tokenDecimals: [TokenId: UInt32] {
        Dictionary(
            tokenTransfersInner.lazy.compactMap { elem in
                guard let decimals = elem.expectedDecimals else {
                    return nil
                }

                return (elem.tokenId, decimals)
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    // /// Create a new `AbstractTokenTransferTransaction`.
    // public override init() {
    //     super.init()
    // }

    /// Add a non-approved token transfer to the transaction.
    ///
    /// `amount` is in the lowest denomination for the token (if the token has `2` decimals this would be `0.01` tokens).
    @discardableResult
    public func tokenTransfer(_ tokenId: TokenId, _ accountId: AccountId, _ amount: Int64) -> Self {
        doTokenTransfer(tokenId, accountId, amount, false)
    }

    /// Add an approved token transfer to the transaction.
    ///
    /// `amount` is in the lowest denomination for the token (if the token has `2` decimals this would be `0.01` tokens).
    @discardableResult
    public func approvedTokenTransfer(_ tokenId: TokenId, _ accountId: AccountId, _ amount: Int64) -> Self {
        doTokenTransfer(tokenId, accountId, amount, true)
    }

    /// Add a non-approved token transfer with decimals to the transaction, ensuring that the token has `expectedDecimals` decimals.
    ///
    /// `amount` is _still_ in the lowest denomination, however,
    /// you will get an error if the token has a different amount of decimals than `expectedDecimals`.
    @discardableResult
    public func tokenTransferWithDecimals(
        _ tokenId: TokenId, _ accountId: AccountId, _ amount: Int64, _ expectedDecimals: UInt32
    ) -> Self {
        doTokenTransferWithDecimals(tokenId, accountId, amount, false, expectedDecimals)
    }

    /// Add an approved token transfer with decimals to the transaction, ensuring that the token has `expectedDecimals` decimals.
    ///
    /// `amount` is _still_ in the lowest denomination, however,
    /// you will get an error if the token has a different amount of decimals than `expectedDecimals`.
    @discardableResult
    public func approvedTokenTransferWithDecimals(
        _ tokenId: TokenId, _ accountId: AccountId, _ amount: Int64, _ expectedDecimals: UInt32
    ) -> Self {
        doTokenTransferWithDecimals(tokenId, accountId, amount, true, expectedDecimals)
    }

    /// Add a non-approved nft transfer to the transaction.
    @discardableResult
    public func nftTransfer(_ nftId: NftId, _ senderAccountId: AccountId, _ receiverAccountId: AccountId)
        -> Self
    {
        doNftTransfer(nftId, senderAccountId, receiverAccountId, false)
    }

    /// Add an approved nft transfer to the transaction.
    @discardableResult
    public func approvedNftTransfer(
        _ nftId: NftId, _ senderAccountId: AccountId, _ receiverAccountId: AccountId
    ) -> Self {
        doNftTransfer(nftId, senderAccountId, receiverAccountId, true)
    }

    private func doTokenTransfer(
        _ tokenId: TokenId,
        _ accountId: AccountId,
        _ amount: Int64,
        _ approved: Bool
    ) -> Self {
        let transfer = Transfer(accountId: accountId, amount: amount, isApproval: approved, preTxAllowanceHook: nil, prePostTxAllowanceHook: nil)

        if let firstIndex = tokenTransfersInner.firstIndex(where: { (tokenTransfer) in tokenTransfer.tokenId == tokenId
        }) {
            let existingTransfers = tokenTransfersInner[firstIndex].transfers

            if let existingTransferIndex = existingTransfers.firstIndex(where: {
                $0.accountId == accountId && $0.isApproval == approved
            }) {
                tokenTransfersInner[firstIndex].transfers[existingTransferIndex].amount += amount
            } else {
                tokenTransfersInner[firstIndex].expectedDecimals = nil
                tokenTransfersInner[firstIndex].transfers.append(transfer)
            }
        } else {
            tokenTransfersInner.append(
                TokenTransfer(
                    tokenId: tokenId,
                    transfers: [transfer],
                    nftTransfers: [],
                    expectedDecimals: nil
                ))
        }

        return self
    }

    private func doTokenTransferWithDecimals(
        _ tokenId: TokenId,
        _ accountId: AccountId,
        _ amount: Int64,
        _ approved: Bool,
        _ expectedDecimals: UInt32
    ) -> Self {
        let transfer = Transfer(accountId: accountId, amount: amount, isApproval: approved, preTxAllowanceHook: nil, prePostTxAllowanceHook: nil)

        if let firstIndex = tokenTransfersInner.firstIndex(where: { (tokenTransfer) in tokenTransfer.tokenId == tokenId
        }) {
            if tokenTransfersInner[firstIndex].expectedDecimals != nil
                && tokenTransfersInner[firstIndex].expectedDecimals != expectedDecimals
            {
                print(
                    "Token \(tokenId) has a different amount of decimals than expected. Expected \(expectedDecimals) but got \(tokenTransfersInner[firstIndex].expectedDecimals!)"
                )
                return self
            }

            let existingTransfers = tokenTransfersInner[firstIndex].transfers

            if let existingTransferIndex = existingTransfers.firstIndex(where: {
                $0.accountId == accountId && $0.isApproval == approved
            }) {
                tokenTransfersInner[firstIndex].transfers[existingTransferIndex].amount += amount
            } else {
                tokenTransfersInner[firstIndex].expectedDecimals = expectedDecimals
                tokenTransfersInner[firstIndex].transfers.append(transfer)
            }
        } else {
            tokenTransfersInner.append(
                TokenTransfer(
                    tokenId: tokenId,
                    transfers: [transfer],
                    nftTransfers: [],
                    expectedDecimals: expectedDecimals
                ))
        }

        return self
    }

    /// Add a non-approved token transfer with a pre-transaction allowance hook to the transaction.
    @discardableResult
    public func tokenTransferWithPreTxHook(_ tokenId: TokenId, _ accountId: AccountId, _ amount: Int64, _ hookCall: HookCall) -> Self {
        doTokenTransferWithHook(tokenId, accountId, amount, false, hookCall, nil)
    }

    /// Add a non-approved token transfer with a pre-post-transaction allowance hook to the transaction.
    @discardableResult
    public func tokenTransferWithPrePostTxHook(_ tokenId: TokenId, _ accountId: AccountId, _ amount: Int64, _ hookCall: HookCall) -> Self {
        doTokenTransferWithHook(tokenId, accountId, amount, false, nil, hookCall)
    }

    /// Add an approved token transfer with a pre-transaction allowance hook to the transaction.
    @discardableResult
    public func approvedTokenTransferWithPreTxHook(_ tokenId: TokenId, _ accountId: AccountId, _ amount: Int64, _ hookCall: HookCall) -> Self {
        doTokenTransferWithHook(tokenId, accountId, amount, true, hookCall, nil)
    }

    /// Add an approved token transfer with a pre-post-transaction allowance hook to the transaction.
    @discardableResult
    public func approvedTokenTransferWithPrePostTxHook(_ tokenId: TokenId, _ accountId: AccountId, _ amount: Int64, _ hookCall: HookCall) -> Self {
        doTokenTransferWithHook(tokenId, accountId, amount, true, nil, hookCall)
    }

    private func doTokenTransferWithHook(
        _ tokenId: TokenId,
        _ accountId: AccountId,
        _ amount: Int64,
        _ approved: Bool,
        _ preTxHook: HookCall?,
        _ prePostTxHook: HookCall?
    ) -> Self {
        let transfer = Transfer(accountId: accountId, amount: amount, isApproval: approved, preTxAllowanceHook: preTxHook, prePostTxAllowanceHook: prePostTxHook)

        if let firstIndex = tokenTransfersInner.firstIndex(where: { (tokenTransfer) in tokenTransfer.tokenId == tokenId
        }) {
            let existingTransfers = tokenTransfersInner[firstIndex].transfers

            if let existingTransferIndex = existingTransfers.firstIndex(where: {
                $0.accountId == accountId && $0.isApproval == approved
            }) {
                tokenTransfersInner[firstIndex].transfers[existingTransferIndex].amount += amount
                tokenTransfersInner[firstIndex].transfers[existingTransferIndex].preTxAllowanceHook = preTxHook
                tokenTransfersInner[firstIndex].transfers[existingTransferIndex].prePostTxAllowanceHook = prePostTxHook
            } else {
                tokenTransfersInner[firstIndex].expectedDecimals = nil
                tokenTransfersInner[firstIndex].transfers.append(transfer)
            }
        } else {
            tokenTransfersInner.append(
                TokenTransfer(
                    tokenId: tokenId,
                    transfers: [transfer],
                    nftTransfers: [],
                    expectedDecimals: nil
                ))
        }

        return self
    }

    private func doNftTransfer(
        _ nftId: NftId,
        _ senderAccountId: AccountId,
        _ receiverAccountId: AccountId,
        _ approved: Bool
    ) -> Self {
        let transfer = NftTransfer(
            senderAccountId: senderAccountId,
            receiverAccountId: receiverAccountId,
            serial: nftId.serial,
            isApproval: approved,
            preTxSenderAllowanceHook: nil,
            prePostTxSenderAllowanceHook: nil,
            preTxReceiverAllowanceHook: nil,
            prePostTxReceiverAllowanceHook: nil
        )

        if let index = tokenTransfersInner.firstIndex(where: { transfer in transfer.tokenId == nftId.tokenId }) {
            var tmp = tokenTransfersInner[index]
            tmp.nftTransfers.append(transfer)
            tokenTransfersInner[index] = tmp
        } else {
            tokenTransfersInner.append(
                TokenTransfer(
                    tokenId: nftId.tokenId,
                    transfers: [],
                    nftTransfers: [transfer],
                    expectedDecimals: nil
                )
            )
        }

        return self
    }

    /// Add a non-approved NFT transfer with sender allowance hooks to the transaction.
    @discardableResult
    public func nftTransferWithSenderHooks(
        _ nftId: NftId, 
        _ senderAccountId: AccountId, 
        _ receiverAccountId: AccountId,
        preTxSenderHook: HookCall? = nil,
        prePostTxSenderHook: HookCall? = nil
    ) -> Self {
        doNftTransferWithHooks(nftId, senderAccountId, receiverAccountId, false, preTxSenderHook, prePostTxSenderHook, nil, nil)
    }

    /// Add a non-approved NFT transfer with receiver allowance hooks to the transaction.
    @discardableResult
    public func nftTransferWithReceiverHooks(
        _ nftId: NftId, 
        _ senderAccountId: AccountId, 
        _ receiverAccountId: AccountId,
        preTxReceiverHook: HookCall? = nil,
        prePostTxReceiverHook: HookCall? = nil
    ) -> Self {
        doNftTransferWithHooks(nftId, senderAccountId, receiverAccountId, false, nil, nil, preTxReceiverHook, prePostTxReceiverHook)
    }

    /// Add a non-approved NFT transfer with both sender and receiver allowance hooks to the transaction.
    @discardableResult
    public func nftTransferWithAllHooks(
        _ nftId: NftId, 
        _ senderAccountId: AccountId, 
        _ receiverAccountId: AccountId,
        preTxSenderHook: HookCall? = nil,
        prePostTxSenderHook: HookCall? = nil,
        preTxReceiverHook: HookCall? = nil,
        prePostTxReceiverHook: HookCall? = nil
    ) -> Self {
        doNftTransferWithHooks(nftId, senderAccountId, receiverAccountId, false, preTxSenderHook, prePostTxSenderHook, preTxReceiverHook, prePostTxReceiverHook)
    }

    /// Add an approved NFT transfer with sender allowance hooks to the transaction.
    @discardableResult
    public func approvedNftTransferWithSenderHooks(
        _ nftId: NftId, 
        _ senderAccountId: AccountId, 
        _ receiverAccountId: AccountId,
        preTxSenderHook: HookCall? = nil,
        prePostTxSenderHook: HookCall? = nil
    ) -> Self {
        doNftTransferWithHooks(nftId, senderAccountId, receiverAccountId, true, preTxSenderHook, prePostTxSenderHook, nil, nil)
    }

    /// Add an approved NFT transfer with receiver allowance hooks to the transaction.
    @discardableResult
    public func approvedNftTransferWithReceiverHooks(
        _ nftId: NftId, 
        _ senderAccountId: AccountId, 
        _ receiverAccountId: AccountId,
        preTxReceiverHook: HookCall? = nil,
        prePostTxReceiverHook: HookCall? = nil
    ) -> Self {
        doNftTransferWithHooks(nftId, senderAccountId, receiverAccountId, true, nil, nil, preTxReceiverHook, prePostTxReceiverHook)
    }

    /// Add an approved NFT transfer with both sender and receiver allowance hooks to the transaction.
    @discardableResult
    public func approvedNftTransferWithAllHooks(
        _ nftId: NftId, 
        _ senderAccountId: AccountId, 
        _ receiverAccountId: AccountId,
        preTxSenderHook: HookCall? = nil,
        prePostTxSenderHook: HookCall? = nil,
        preTxReceiverHook: HookCall? = nil,
        prePostTxReceiverHook: HookCall? = nil
    ) -> Self {
        doNftTransferWithHooks(nftId, senderAccountId, receiverAccountId, true, preTxSenderHook, prePostTxSenderHook, preTxReceiverHook, prePostTxReceiverHook)
    }

    private func doNftTransferWithHooks(
        _ nftId: NftId,
        _ senderAccountId: AccountId,
        _ receiverAccountId: AccountId,
        _ approved: Bool,
        _ preTxSenderHook: HookCall?,
        _ prePostTxSenderHook: HookCall?,
        _ preTxReceiverHook: HookCall?,
        _ prePostTxReceiverHook: HookCall?
    ) -> Self {
        let transfer = NftTransfer(
            senderAccountId: senderAccountId,
            receiverAccountId: receiverAccountId,
            serial: nftId.serial,
            isApproval: approved,
            preTxSenderAllowanceHook: preTxSenderHook,
            prePostTxSenderAllowanceHook: prePostTxSenderHook,
            preTxReceiverAllowanceHook: preTxReceiverHook,
            prePostTxReceiverAllowanceHook: prePostTxReceiverHook
        )

        if let index = tokenTransfersInner.firstIndex(where: { transfer in transfer.tokenId == nftId.tokenId }) {
            var tmp = tokenTransfersInner[index]
            tmp.nftTransfers.append(transfer)
            tokenTransfersInner[index] = tmp
        } else {
            tokenTransfersInner.append(
                TokenTransfer(
                    tokenId: nftId.tokenId,
                    transfers: [],
                    nftTransfers: [transfer],
                    expectedDecimals: nil
                )
            )
        }

        return self
    }

    internal func sortTransfers() -> [TokenTransfer] {
        var transferLists = tokenTransfersInner

        // Sort token transfers by token ID
        transferLists.sort { a, b in
            if a.tokenId.shard != b.tokenId.shard {
                return a.tokenId.shard < b.tokenId.shard
            }
            if a.tokenId.realm != b.tokenId.realm {
                return a.tokenId.realm < b.tokenId.realm
            }
            return a.tokenId.num < b.tokenId.num
        }

        // Sort transfers within each TokenTransfer
        for index in transferLists.indices {
            transferLists[index].transfers.sort { (a: Transfer, b: Transfer) in
                if a.accountId.shard != b.accountId.shard {
                    return a.accountId.shard < b.accountId.shard
                }
                if a.accountId.realm != b.accountId.realm {
                    return a.accountId.realm < b.accountId.realm
                }
                if a.accountId.num != b.accountId.num {
                    return a.accountId.num < b.accountId.num
                }
                return a.isApproval && !b.isApproval
            }

            transferLists[index].nftTransfers.sort { $0.serial < $1.serial }
        }

        return transferLists
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try transfers.validateChecksums(on: ledgerId)
        try tokenTransfersInner.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}

extension AbstractTokenTransferTransaction.Transfer: TryProtobufCodable {
    internal typealias Protobuf = Proto_AccountAmount

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            accountId: try .fromProtobuf(proto.accountID),
            amount: proto.amount,
            isApproval: proto.isApproval,
            preTxAllowanceHook: nil,
            prePostTxAllowanceHook: nil
        )
        
        // Handle hook calls
        switch proto.hookCall {
        case .preTxAllowanceHook(let hookCall):
            self.preTxAllowanceHook = try HookCall(protobuf: hookCall)
        case .prePostTxAllowanceHook(let hookCall):
            self.prePostTxAllowanceHook = try HookCall(protobuf: hookCall)
        case nil:
            break
        }
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.accountID = accountId.toProtobuf()
            proto.amount = amount
            proto.isApproval = isApproval
            
            // Handle hook calls
            if let preTxHook = preTxAllowanceHook {
                proto.hookCall = .preTxAllowanceHook(preTxHook.toProtobuf())
            } else if let prePostTxHook = prePostTxAllowanceHook {
                proto.hookCall = .prePostTxAllowanceHook(prePostTxHook.toProtobuf())
            }
        }
    }
}

extension AbstractTokenTransferTransaction.TokenTransfer: TryProtobufCodable {
    internal typealias Protobuf = Proto_TokenTransferList

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            tokenId: .fromProtobuf(proto.token),
            transfers: try .fromProtobuf(proto.transfers),
            nftTransfers: try .fromProtobuf(proto.nftTransfers),
            expectedDecimals: proto.hasExpectedDecimals ? proto.expectedDecimals.value : nil
        )
        transfers = try .fromProtobuf(proto.transfers)

    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.token = tokenId.toProtobuf()
            proto.transfers = transfers.toProtobuf()
            proto.nftTransfers = nftTransfers.toProtobuf()
            if let expectedDecimals = expectedDecimals {
                proto.expectedDecimals = Google_Protobuf_UInt32Value(expectedDecimals)
            }
        }
    }
}

extension AbstractTokenTransferTransaction.NftTransfer: TryProtobufCodable {
    internal typealias Protobuf = Proto_NftTransfer

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            senderAccountId: try .fromProtobuf(proto.senderAccountID),
            receiverAccountId: try .fromProtobuf(proto.receiverAccountID),
            serial: UInt64(proto.serialNumber),
            isApproval: proto.isApproval,
            preTxSenderAllowanceHook: nil,
            prePostTxSenderAllowanceHook: nil,
            preTxReceiverAllowanceHook: nil,
            prePostTxReceiverAllowanceHook: nil
        )
        
        // Handle sender allowance hook calls
        switch proto.senderAllowanceHookCall {
        case .preTxSenderAllowanceHook(let hookCall):
            self.preTxSenderAllowanceHook = try HookCall(protobuf: hookCall)
        case .prePostTxSenderAllowanceHook(let hookCall):
            self.prePostTxSenderAllowanceHook = try HookCall(protobuf: hookCall)
        case nil:
            break
        }
        
        // Handle receiver allowance hook calls
        switch proto.receiverAllowanceHookCall {
        case .preTxReceiverAllowanceHook(let hookCall):
            self.preTxReceiverAllowanceHook = try HookCall(protobuf: hookCall)
        case .prePostTxReceiverAllowanceHook(let hookCall):
            self.prePostTxReceiverAllowanceHook = try HookCall(protobuf: hookCall)
        case nil:
            break
        }
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.senderAccountID = senderAccountId.toProtobuf()
            proto.receiverAccountID = receiverAccountId.toProtobuf()
            proto.serialNumber = Int64(bitPattern: serial)
            proto.isApproval = isApproval
            
            // Handle sender allowance hook calls
            if let preTxSenderHook = preTxSenderAllowanceHook {
                proto.senderAllowanceHookCall = .preTxSenderAllowanceHook(preTxSenderHook.toProtobuf())
            } else if let prePostTxSenderHook = prePostTxSenderAllowanceHook {
                proto.senderAllowanceHookCall = .prePostTxSenderAllowanceHook(prePostTxSenderHook.toProtobuf())
            }
            
            // Handle receiver allowance hook calls
            if let preTxReceiverHook = preTxReceiverAllowanceHook {
                proto.receiverAllowanceHookCall = .preTxReceiverAllowanceHook(preTxReceiverHook.toProtobuf())
            } else if let prePostTxReceiverHook = prePostTxReceiverAllowanceHook {
                proto.receiverAllowanceHookCall = .prePostTxReceiverAllowanceHook(prePostTxReceiverHook.toProtobuf())
            }
        }
    }
}

extension TokenNftTransfer {
    fileprivate init(nftTransfer: TransferTransaction.NftTransfer, withTokenId tokenId: TokenId) {
        self.init(
            tokenId: tokenId,
            sender: nftTransfer.senderAccountId,
            receiver: nftTransfer.receiverAccountId,
            serial: nftTransfer.serial,
            isApproved: nftTransfer.isApproval
        )
    }
}
