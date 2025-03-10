// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

internal struct PingQuery {
    internal init(nodeAccountId: AccountId) {
        self.nodeAccountId = nodeAccountId
    }

    private let nodeAccountId: AccountId

    internal func execute(_ client: Client, timeout: TimeInterval? = nil) async throws {
        try await executeAny(client, self, timeout)
    }
}

extension PingQuery: ValidateChecksums {
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try nodeAccountId.validateChecksums(on: ledgerId)
    }
}

extension PingQuery: Execute {
    internal typealias GrpcRequest = Proto_Query

    internal typealias GrpcResponse = Proto_Response

    internal typealias Context = Void

    internal typealias Response = Void

    internal var nodeAccountIds: [AccountId]? {
        [nodeAccountId]
    }

    internal var explicitTransactionId: TransactionId? { nil }

    internal var operatorAccountId: AccountId? {
        nil
    }

    internal var regenerateTransactionId: Bool? {
        false
    }

    internal var requiresTransactionId: Bool { false }

    internal var firstTransactionId: TransactionId? {
        nil
    }

    internal var index: Int? {
        nil
    }

    internal func makeRequest(_ transactionId: TransactionId?, _ nodeAccountId: AccountId) throws -> (Proto_Query, ()) {
        let header = Proto_QueryHeader.with { $0.responseType = .answerOnly }

        assert(nodeAccountId == self.nodeAccountId)

        let query = Proto_Query.with { proto in
            proto.query = .cryptogetAccountBalance(
                .with { proto in
                    proto.accountID = nodeAccountId.toProtobuf()
                    proto.header = header
                }
            )
        }

        return (query, ())
    }

    internal func execute(_ channel: GRPC.GRPCChannel, _ request: Proto_Query) async throws -> Proto_Response {
        try await Proto_CryptoServiceAsyncClient(channel: channel).cryptoGetBalance(request)
    }

    internal func makeResponse(
        _ response: Proto_Response, _ context: (), _ nodeAccountId: AccountId, _ transactionId: TransactionId?
    ) throws {}

    internal func makeErrorPrecheck(_ status: Status, _ transactionId: TransactionId?) -> HError {
        HError(
            kind: .queryNoPaymentPreCheckStatus(status: status),
            description: "query with no payment transaction failed pre-check with status \(status)"
        )
    }

    internal static func responsePrecheckStatus(_ response: HieroProtobufs.Proto_Response) throws -> Int32 {
        try Int32(response.header().nodeTransactionPrecheckCode.rawValue)
    }
}
