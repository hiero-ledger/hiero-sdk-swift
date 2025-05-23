// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

internal struct QueryCost<T, U: Query<T>> {
    private let query: U

    internal init(query: U) {
        self.query = query
    }

    internal func execute(_ client: Client, _ timeout: TimeInterval? = nil) async throws -> Response {
        try await executeAny(client, self, timeout)
    }
}

extension QueryCost: Execute {
    internal typealias GrpcRequest = Proto_Query

    internal typealias GrpcResponse = Proto_Response

    internal typealias Response = Hbar

    internal typealias Context = ()

    internal var nodeAccountIds: [AccountId]? {
        query.nodeAccountIds
    }

    internal var explicitTransactionId: TransactionId? { nil }

    internal var operatorAccountId: AccountId? {
        nil
    }

    internal var regenerateTransactionId: Bool? {
        false
    }

    internal var firstTransactionId: TransactionId? {
        nil
    }

    internal var index: Int? {
        nil
    }

    internal var requiresTransactionId: Bool { false }

    internal func makeRequest(_ transactionId: TransactionId?, _ nodeAccountId: AccountId) throws -> (Proto_Query, ()) {
        let request = query.toQueryProtobufWith(
            .with { proto in
                proto.responseType = .costAnswer
            })

        return (request, ())
    }

    internal func execute(_ channel: GRPCChannel, _ request: Proto_Query) async throws
        -> Proto_Response
    {
        try await query.queryExecute(channel, request)
    }

    internal func makeResponse(
        _ response: Proto_Response, _ context: (), _ nodeAccountId: AccountId,
        _ transactionId: TransactionId?
    ) throws -> Hbar {
        let header = try response.header()

        return query.mapCost(.fromTinybars(Int64(header.cost)))
    }

    internal func makeErrorPrecheck(_ status: Status, _ transactionId: TransactionId?) -> HError {
        if let transactionId = query.relatedTransactionId {
            return HError(
                kind: .queryPreCheckStatus(status: status, transactionId: transactionId),
                description: "query for transaction `\(transactionId)` failed pre-check with status `\(status)`"
            )
        }

        if let transactionId = transactionId {
            return HError(
                kind: .queryPaymentPreCheckStatus(status: status, transactionId: transactionId),
                description:
                    "query with payment transaction `\(transactionId)` failed pre-check with status `\(status)`"
            )
        }

        return HError(
            kind: .queryNoPaymentPreCheckStatus(status: status),
            description: "query with no payment transaction failed pre-check with status `\(status)`"
        )
    }

    internal static func responsePrecheckStatus(_ response: Proto_Response) throws -> Int32 {
        Int32(try response.header().nodeTransactionPrecheckCode.rawValue)
    }
}

extension QueryCost: ValidateChecksums {
    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try query.validateChecksums(on: ledgerId)
    }
}
