// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Liveness probe used by `Client.ping()` / `Client.pingAll()` and by the node health check in `Execute`.
///
/// Sends a `CryptoService/getAccountInfo` query for account `<shard>.<realm>.2` with
/// `ResponseType = COST_ANSWER`: the node answers with the query fee without executing it,
/// so nothing is charged and no operator is required. A cost response is success; a gRPC
/// failure or a non-OK precheck is failure.
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
        assert(nodeAccountId == self.nodeAccountId)

        // Account 2 in the node's shard/realm (`0.0.2` on every current network), as in the other SDKs.
        let probeAccountId = AccountId(shard: nodeAccountId.shard, realm: nodeAccountId.realm, num: 2)

        let query = Proto_Query.with { proto in
            proto.cryptoGetInfo = .with { proto in
                proto.header = .with { $0.responseType = .costAnswer }
                proto.accountID = probeAccountId.toProtobuf()
            }
        }

        return (query, ())
    }

    internal func execute(_ channel: GRPC.GRPCChannel, _ request: Proto_Query, _ deadline: TimeInterval) async throws
        -> Proto_Response
    {
        try await Proto_CryptoServiceAsyncClient(channel: channel).getAccountInfo(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal func makeResponse(
        _ response: Proto_Response, _ context: (), _ nodeAccountId: AccountId, _ transactionId: TransactionId?
    ) throws {
        guard case .cryptoGetInfo = response.response else {
            throw HError.fromProtobuf(
                "unexpected \(String(describing: response.response)) received, expected `cryptoGetInfo`")
        }
    }

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
