// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// A transaction that can be executed on the Hedera network.
public class Transaction: ValidateChecksums {
    public typealias Response = TransactionResponse

    public init() {}

    internal init(protobuf proto: Proto_TransactionBody) throws {
        transactionValidDuration = .fromProtobuf(proto.transactionValidDuration)
        maxTransactionFee = .fromTinybars(Int64(proto.transactionFee))
        transactionMemo = proto.memo
        transactionId = (try? .fromProtobuf(proto.transactionID)) ?? nil
        customFeeLimits = try .fromProtobuf(proto.maxCustomFees)
    }

    internal private(set) final var signers: [Signer] = []
    internal final var sources: TransactionSources?
    public private(set) final var isFrozen: Bool = false

    private final var `operator`: Operator?

    internal var defaultMaxTransactionFee: Hbar {
        2
    }

    internal static let dummyAccountId = AccountId(0)
    internal static let dummyId = TransactionId.withValidStart(
        dummyAccountId, Timestamp(fromUnixTimestampNanos: 0))

    internal func toTransactionDataProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody.OneOf_Data {
        fatalError("Method `Transaction.toTransactionDataProtobuf` must be overridden by `\(type(of: self))`")
    }

    internal func transactionExecute(_ channel: GRPCChannel, _ request: Proto_Transaction) async throws
        -> Proto_TransactionResponse
    {
        fatalError("Method `Transaction.transactionExecute` must be overridden by `\(type(of: self))`")
    }

    public final var nodeAccountIds: [AccountId]? {
        willSet {
            ensureNotFrozen(fieldName: "nodeAccountIds")
        }
    }

    @discardableResult
    public func nodeAccountIds(_ nodeAccountIds: [AccountId]) -> Self {
        self.nodeAccountIds = nodeAccountIds

        return self
    }

    /// The maximum allowed transaction fee for this transaction.
    public final var maxTransactionFee: Hbar? {
        willSet {
            ensureNotFrozen(fieldName: "maxTransactionFee")
        }
    }

    /// Sets the maximum allowed transaction fee for this transaction.
    @discardableResult
    public final func maxTransactionFee(_ maxTransactionFee: Hbar) -> Self {
        self.maxTransactionFee = maxTransactionFee

        return self
    }

    public final var transactionValidDuration: Duration? {
        willSet {
            ensureNotFrozen(fieldName: "transactionValidDuration")
        }
    }

    @discardableResult
    public final func transactionValidDuration(_ transactionValidDuration: Duration) -> Self {
        self.transactionValidDuration = transactionValidDuration

        return self
    }

    public final var transactionMemo: String = "" {
        willSet {
            ensureNotFrozen(fieldName: "transactionMemo")
        }
    }

    @discardableResult
    public final func transactionMemo(_ transactionMemo: String) -> Self {
        self.transactionMemo = transactionMemo

        return self
    }

    /// Explicit transaction ID for this transaction.
    public final var transactionId: TransactionId? {
        willSet {
            ensureNotFrozen(fieldName: "transactionId")
        }
    }

    /// Sets the explicit transaction ID for this transaction.
    @discardableResult
    public final func transactionId(_ transactionId: TransactionId) -> Self {
        self.transactionId = transactionId

        return self
    }

    /// Whether or not the transaction ID should be refreshed if a ``Status/transactionExpired`` occurs.
    ///
    /// By default, the value on ``Client`` will be used.
    ///
    /// >Note: Some operations forcibly disable transaction ID regeneration, such as setting the transaction ID explicitly.
    public final var regenerateTransactionId: Bool? {
        willSet {
            ensureNotFrozen(fieldName: "regenerateTransactionId")
        }
    }

    /// Sets whether or not the transaction ID should be refreshed if a ``Status/transactionExpired`` occurs.
    ///
    /// Various operations such as setting the transaction ID exlicitly can forcibly disable transaction ID regeneration.
    @discardableResult
    public final func regenerateTransactionId(_ regenerateTransactionId: Bool) -> Self {
        self.regenerateTransactionId = regenerateTransactionId

        return self
    }

    /// The custom fees that will be applied to the transaction.
    internal final var customFeeLimits: [CustomFeeLimit] = [] {
        willSet {
            ensureNotFrozen(fieldName: "customFeeLimits")
        }
    }

    /// Sets the custom fees that will be applied to the transaction.
    @discardableResult
    internal func customFeeLimits(_ customFeeLimits: [CustomFeeLimit]) -> Self {
        self.customFeeLimits = customFeeLimits

        return self
    }

    /// Adds a custom fee limit to the list of custom fee limits.
    @discardableResult
    internal func addCustomFeeLimit(_ customFeeLimit: CustomFeeLimit) -> Self {
        self.customFeeLimits.append(customFeeLimit)

        return self
    }

    /// Clears the custom fee limit for the topic.
    @discardableResult
    internal func clearCustomFeeLimits() -> Self {
        self.customFeeLimits = []

        return self
    }

    /// Explicit batch key for this batch transactions.
    public final var batchKey: Key? {
        willSet {
            ensureNotFrozen(fieldName: "batchKey")
        }
    }

    /// Set the batch key.
    @discardableResult
    public func batchKey(_ key: Key) -> Self {
        self.batchKey = key

        return self
    }

    /// Batchify the transaction with the given batch key.
    ///
    /// The transaction will be frozen and signed by the operator of the client.
    @discardableResult
    public func batchify(client: Client, _ batchKey: Key) throws -> Self {
        self.batchKey = batchKey
        self.nodeAccountIds = [Transaction.dummyAccountId]

        try self.signWithOperator(client)

        return self
    }

    /// Adds a signature directly to `self`.
    ///
    /// Only use this as a last resort.
    ///
    /// This forcibly disables transaction ID regeneration.
    @discardableResult
    public final func addSignature(_ publicKey: PublicKey, _ signature: Data) -> Self {
        _ = self.addSignatureSigner(Signer(publicKey) { _ in signature })

        return self
    }

    internal func addSignatureSigner(_ signer: Signer) -> Data {
        precondition(isFrozen)

        precondition(nodeAccountIds?.count == 1, "cannot manually add a signature to a transaction with multiple nodes")

        // swiftlint:disable:next force_try
        let sources = try! makeSources()

        // hack: I don't care about perf here.
        let ret = signer(sources.signedTransactions[0].bodyBytes).1

        self.sources = sources.signWithSigners([signer])

        return ret
    }

    public final func schedule() -> ScheduleCreateTransaction {
        self.ensureNotFrozen()

        precondition(
            nodeAccountIds?.isEmpty ?? true,
            "The underlying transaction for a scheduled transaction cannot have node account IDs set")

        let transaction = ScheduleCreateTransaction()

        if let transactionId = transactionId {
            transaction.transactionId(transactionId)
        }

        transaction.scheduledTransaction(self)

        return transaction
    }

    /// Get the hash for this transaction.
    ///
    /// >Note: Calling this function _disables_ transaction ID regeneration.
    public func getTransactionHash() throws -> TransactionHash {
        // todo: error not frozen
        precondition(
            isFrozen,
            "Transaction must be frozen before calling `getTransactionHash`"
        )

        let sources = try self.makeSources()

        self.sources = sources

        return TransactionHash(hashing: sources.transactions.first!.signedTransactionBytes)
    }

    /// Get the hashes for this transaction.
    ///
    /// >Note: Calling this function _disables_ transaction ID regeneration.
    public func getTransactionHashPerNode() throws -> [AccountId: TransactionHash] {
        // todo: error not frozen
        precondition(
            isFrozen,
            "Transaction must be frozen before calling `getTransactionHashPerNode`"
        )

        let sources = try self.makeSources()

        self.sources = sources

        let chunk = sources.chunks.first!

        return Dictionary(
            zip(chunk.nodeIds, chunk.transactions).lazy.map {
                ($0.0, TransactionHash(hashing: $0.1.signedTransactionBytes))
            },
            uniquingKeysWith: { (first, _) in first })
    }

    @discardableResult
    public final func sign(_ privateKey: PrivateKey) -> Self {
        self.signWithSigner(.privateKey(privateKey))

        return self
    }

    @discardableResult
    public final func signWith(_ publicKey: PublicKey, _ signer: @Sendable @escaping (Data) -> (Data)) -> Self {
        self.signWithSigner(Signer(publicKey, signer))

        return self
    }

    /// Sign tthis transaction with the operator on the provided client.
    @discardableResult
    public final func signWithOperator(_ client: Client) throws -> Self {
        guard let `operator` = client.operator else {
            fatalError("todo: error here (Client had no operator)")
        }

        try freezeWith(client)

        signWithSigner(`operator`.signer)

        return self
    }

    public final func getSignatures() throws -> [AccountId: [PublicKey: Data]] {
        let sources = try self.makeSources()

        self.sources = sources

        precondition(sources.chunksCount == 1, "called `getSignatures` on a chunked transaction with chunks")

        return try Transaction.getSignaturesAtOffset(chunk: sources.chunks.first!)
    }

    /// Get the Signatures for this transaction
    ///
    internal static func getSignaturesAtOffset(chunk: SourceChunk) throws -> [AccountId: [PublicKey:
        Data]]
    {
        let signaturesPerNode = try zip(chunk.nodeIds, chunk.signedTransactions).lazy.map { nodeId, tx in
            let sigs = try tx.sigMap.sigPair.lazy.map { sigPair in
                let key = try PublicKey.fromBytes(sigPair.pubKeyPrefix)
                let value: Data
                switch sigPair.signature {
                case .ed25519(let data),
                    .ecdsaSecp256K1(let data):
                    value = data
                default: value = Data()
                }
                return (key, value)
            }

            return (nodeId, Dictionary(uniqueKeysWithValues: sigs))
        }

        return Dictionary(uniqueKeysWithValues: signaturesPerNode)
    }

    internal final func signWithSigner(_ signer: Signer) {
        guard !signers.contains(where: { $0.publicKey == signer.publicKey }) else {
            return
        }

        self.signers.append(signer)
    }

    @discardableResult
    public final func freeze() throws -> Self {
        try freezeWith(nil)
    }

    @discardableResult
    public func freezeWith(_ client: Client?) throws -> Self {
        if isFrozen {
            return self
        }

        /// If no transaction ID, generate one.
        if self.transactionId == nil {
            guard let client = client else {
                throw HError.unitialized(
                    "If no client is provided to freeze transaction, the transaction ID must be manually set.")
            }

            guard let `operator` = client.operator else {
                throw HError.unitialized("Client operator has not been initialized and cannot freeze transaction.")
            }

            self.`operator` = `operator`
            self.transactionId = `operator`.generateTransactionId()
        }

        /// If the node account IDs aren't provided, generate them.
        if self.nodeAccountIds == nil {
            guard let client = client else {
                throw HError.unitialized(
                    "If no client is provided to freeze transaction, the node account ID(s) must be manually set.")
            }

            self.`operator` = client.operator
            self.nodeAccountIds = client.consensus.selectHealthyNodeSample()
        }

        self.maxTransactionFee = self.maxTransactionFee ?? client?.maxTransactionFee

        isFrozen = true

        if client?.isAutoValidateChecksumsEnabled() == true {
            try validateChecksums(on: client!)
        }

        return self
    }

    @discardableResult
    internal final func makeSources() throws -> TransactionSources {
        if let sources = sources {
            return sources.signWithSigners(self.signers)
        }

        let transactions = try self.makeTransactionList()

        // swiftlint:disable:next force_try
        return try! TransactionSources(transactions: transactions)
    }

    public func execute(_ client: Client, _ timeout: TimeInterval? = nil) async throws -> Response {
        try freezeWith(client)

        if let sources = sources {
            return try await SourceTransaction(inner: self, sources: sources).execute(client, timeout: timeout)
        }

        try signWithOperator(client)

        return try await executeAny(client, self, timeout)
    }

    public static func fromBytes(_ bytes: Data) throws -> Transaction {
        let list: [Proto_Transaction]
        do {
            let tmp = try Proto_TransactionList(serializedBytes: bytes)

            if tmp.transactionList.isEmpty {
                list = [try Proto_Transaction(serializedBytes: bytes)]
            } else {
                list = tmp.transactionList
            }
        } catch {
            throw HError.fromProtobuf(String(describing: error))
        }

        let sources = try TransactionSources(transactions: list)

        let transactionBodies = try sources.signedTransactions.map { signed -> Proto_TransactionBody in
            do {
                return try Proto_TransactionBody(serializedBytes: signed.bodyBytes)
            } catch {
                throw HError.fromProtobuf(String(describing: error))
            }
        }

        do {
            let (first, rest) = (transactionBodies[0], transactionBodies[1...])

            for body in rest {
                guard protoTransactionBodyEqual(body, first) else {
                    throw HError.fromProtobuf("transaction parts unexpectedly unequal")
                }
            }

        }

        let transactionData =
            try sources
            .chunks
            .compactMap { $0.signedTransactions.first }
            .lazy
            .map { signed -> Proto_TransactionBody in
                do {
                    return try Proto_TransactionBody(serializedBytes: signed.bodyBytes)
                } catch {
                    throw HError.fromProtobuf(String(describing: error))
                }

            }
            .map { body -> Proto_TransactionBody.OneOf_Data in
                guard let data = body.data else {
                    throw HError.fromProtobuf("Unexpected missing `data`")
                }

                return data
            }

        // note: this creates the transaction in a unfrozen state by pure need.
        let transaction = try Transaction.fromProtobuf(transactionBodies[0], transactionData)

        transaction.nodeAccountIds =
            (sources.nodeAccountIds.count == 1 && sources.nodeAccountIds[0] == Transaction.dummyAccountId)
            ? nil : sources.nodeAccountIds
        transaction.sources = sources

        return transaction
    }

    public final func toBytes() throws -> Data {
        if let sources = self.sources?.signWithSigners(self.signers) {
            return sources.toBytes()
        }

        let transactionList = try Proto_TransactionList.with { proto in
            proto.transactionList = try self.makeTransactionList()
        }

        // swiftlint:disable:next force_try
        return try! transactionList.serializedData()
    }

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try nodeAccountIds?.validateChecksums(on: ledgerId)
        try transactionId?.validateChecksums(on: ledgerId)
    }

    internal final func ensureNotFrozen(fieldName: String? = nil) {
        if let fieldName = fieldName {
            precondition(!isFrozen, "\(fieldName) cannot be set while `\(type(of: self))` is frozen")
        } else {
            precondition(
                !isFrozen,
                "`\(type(of: self))` is immutable; it has at least one signature or has been explicitly frozen")
        }
    }
}

extension Transaction {
    internal final func makeResponse(
        _: Proto_TransactionResponse, _ context: TransactionHash, _ nodeAccountId: AccountId,
        _ transactionId: TransactionId?
    ) -> Response {
        return TransactionResponse(
            nodeAccountId: nodeAccountId, transactionId: transactionId!, transactionHash: context)
    }

    internal final func makeErrorPrecheck(_ status: Status, _ transactionId: TransactionId?) -> HError {
        let transactionId = transactionId!

        return HError(
            kind: .transactionPreCheckStatus(status: status, transactionId: transactionId),
            description: "transaction `\(transactionId)` failed pre-check with status `\(status)`"
        )
    }

    internal static func responsePrecheckStatus(_ response: Proto_TransactionResponse) -> Int32 {
        Int32(response.nodeTransactionPrecheckCode.rawValue)
    }
}

extension Transaction {
    fileprivate func makeTransactionList() throws -> [Proto_Transaction] {

        let initialTransactionId =
            self.transactionId ?? self.operator?.generateTransactionId() ?? Transaction.dummyId

        let usedChunks = (self as? ChunkedTransaction)?.usedChunks ?? 1
        let nodeAccountIds = nodeAccountIds ?? [Transaction.dummyAccountId]

        var transactionList: [Proto_Transaction] = []

        // Note: This ordering is *important*,
        // there's no documentation for it but `TransactionList` is sorted by chunk number,
        // then `node_id` (in the order they were added to the transaction)
        for chunk in 0..<usedChunks {
            let currentTransactionId: TransactionId =
                (chunk == 0)
                ? initialTransactionId
                : TransactionId(
                    accountId: initialTransactionId.accountId,
                    validStart: initialTransactionId.validStart.adding(nanos: UInt64(chunk)))

            for nodeAccountId in nodeAccountIds {
                let chunkInfo = ChunkInfo(
                    current: chunk,
                    total: usedChunks,
                    initialTransactionId: initialTransactionId,
                    currentTransactionId: currentTransactionId,
                    nodeAccountId: nodeAccountId
                )

                transactionList.append(self.makeRequestInner(chunkInfo: chunkInfo).0)
            }
        }

        return transactionList
    }

    internal func makeRequestInner(chunkInfo: ChunkInfo) -> (Proto_Transaction, TransactionHash) {
        let body: Proto_TransactionBody = self.toTransactionBodyProtobuf(chunkInfo)

        // swiftlint:disable:next force_try
        let bodyBytes = try! body.serializedData()

        var signatures: [SignaturePair] = []

        if let `operator` = self.operator {
            let operatorSignature = `operator`.signer(bodyBytes)

            signatures.append(SignaturePair(operatorSignature))
        }

        for signer in self.signers where signatures.allSatisfy({ $0.publicKey != signer.publicKey }) {
            let signature = signer(bodyBytes)
            signatures.append(SignaturePair(signature))
        }

        let signedTransaction = Proto_SignedTransaction.with { proto in
            proto.bodyBytes = bodyBytes
            proto.sigMap.sigPair = signatures.toProtobuf()
        }

        // swiftlint:disable:next force_try
        let signedTransactionBytes = try! signedTransaction.serializedData()

        let transactionHash = TransactionHash(hashing: signedTransactionBytes)

        let transaction = Proto_Transaction.with { $0.signedTransactionBytes = signedTransactionBytes }

        return (transaction, transactionHash)
    }

    private func toTransactionBodyProtobuf(_ chunkInfo: ChunkInfo) -> Proto_TransactionBody {
        let data = toTransactionDataProtobuf(chunkInfo)

        let maxTransactionFee = self.maxTransactionFee ?? self.defaultMaxTransactionFee

        let customFeeLimits = self.customFeeLimits

        return .with { proto in
            proto.data = data

            if chunkInfo.currentTransactionId != Transaction.dummyId {
                proto.transactionID = chunkInfo.currentTransactionId.toProtobuf()
            }

            if let batchKey = batchKey {
                proto.batchKey = batchKey.toProtobuf()
            }

            proto.transactionValidDuration = (self.transactionValidDuration ?? .minutes(2)).toProtobuf()
            proto.memo = self.transactionMemo

            if chunkInfo.nodeAccountId != Transaction.dummyAccountId {
                proto.nodeAccountID = chunkInfo.nodeAccountId.toProtobuf()
            }

            proto.generateRecord = false
            proto.transactionFee = UInt64(maxTransactionFee.toTinybars())
            if !customFeeLimits.isEmpty {
                proto.maxCustomFees = customFeeLimits.map { $0.toProtobuf() }
            }
        }
    }
}

extension Transaction: Execute {
    internal typealias GrpcRequest = Proto_Transaction
    internal typealias GrpcResponse = Proto_TransactionResponse
    internal typealias Context = TransactionHash

    internal var explicitTransactionId: TransactionId? {
        transactionId
    }

    internal var requiresTransactionId: Bool { true }

    internal var firstTransactionId: TransactionId? { nil }

    internal var index: Int? { nil }

    internal var operatorAccountId: AccountId? {
        self.operator?.accountId
    }

    internal func makeRequest(_ transactionId: TransactionId?, _ nodeAccountId: AccountId) throws -> (
        GrpcRequest, TransactionHash
    ) {
        assert(isFrozen)

        guard let transactionId = transactionId else {
            throw HError.noPayerAccountOrTransactionId
        }

        return self.makeRequestInner(chunkInfo: .single(transactionId: transactionId, nodeAccountId: nodeAccountId))
    }

    internal func execute(_ channel: any GRPCChannel, _ request: GrpcRequest) async throws -> GrpcResponse {
        try await transactionExecute(channel, request)
    }
}

/// Returns true if `lhs == rhs`` other than `transactionId` and `nodeAccountId`, false otherwise.
private func protoTransactionBodyEqual(_ lhs: Proto_TransactionBody, _ rhs: Proto_TransactionBody) -> Bool {
    guard lhs.transactionFee == rhs.transactionFee else {
        return false
    }

    guard lhs.transactionValidDuration == rhs.transactionValidDuration else {
        return false
    }

    guard lhs.generateRecord == rhs.generateRecord else {
        return false
    }

    guard lhs.memo == rhs.memo else {
        return false
    }

    let lhsData: Proto_TransactionBody.OneOf_Data
    let rhsData: Proto_TransactionBody.OneOf_Data

    switch (lhs.data, rhs.data) {
    case (nil, nil):
        return true

    case (.some, nil), (nil, .some):
        return false

    case (.some(let lhs), .some(let rhs)):
        lhsData = lhs
        rhsData = rhs
    }

    switch (lhsData, rhsData) {
    case (.consensusSubmitMessage(let lhs), .consensusSubmitMessage(let rhs)):
        guard lhs.hasTopicID == rhs.hasTopicID else {
            return false
        }

        guard lhs.topicID == rhs.topicID else {
            return false
        }

        guard lhs.hasChunkInfo == rhs.hasChunkInfo else {
            return false
        }

        if lhs.hasChunkInfo /* && rhs.hasChunkInfo */ {
            guard lhs.chunkInfo.initialTransactionID == rhs.chunkInfo.initialTransactionID else {
                return false
            }

            guard lhs.chunkInfo.total == rhs.chunkInfo.total else {
                return false
            }

            guard lhs.unknownFields == rhs.unknownFields else {
                return false
            }

            // allow lhs.chunkInfo.number != rhs.chunkInfo.number
        }

    // allow lhs.message != rhs.message

    case (.fileAppend(let lhs), .fileAppend(let rhs)):
        guard lhs.fileID == rhs.fileID else {
            return false
        }

        // allow lhs.contents != rhs.contents

        guard lhs.unknownFields == rhs.unknownFields else {
            return false
        }

    default:
        guard lhsData == rhsData else {
            return false
        }
    }

    return true
}

extension Transaction {
    /// Converts an array of transactions to their protobuf representation.
    /// - Parameter transactions: The array of transactions to convert
    /// - Returns: An array of protobuf transactions
    /// - Throws: If any transaction fails to convert
    internal static func toSerializedProtoTransactions(_ transactions: [Transaction]) throws -> [Data] {
        var protoTransactions: [Data] = []

        for transaction in transactions {
            guard let nodeAccountIds = transaction.nodeAccountIds else {
                throw HError(
                    kind: .freezeUnsetNodeAccountIds, description: "Transaction must have node account IDs set")
            }

            for nodeAccountId in nodeAccountIds {
                guard let transactionId = transaction.transactionId ?? transaction.operator?.generateTransactionId()
                else {
                    throw HError.noPayerAccountOrTransactionId
                }

                let chunkInfo = ChunkInfo(
                    current: 0,
                    total: 1,
                    initialTransactionId: transactionId,
                    currentTransactionId: transactionId,
                    nodeAccountId: nodeAccountId
                )

                protoTransactions.append(try transaction.makeRequestInner(chunkInfo: chunkInfo).0.serializedBytes())
            }
        }

        return protoTransactions
    }
}
