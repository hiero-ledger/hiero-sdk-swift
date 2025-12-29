// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Get information about a smart contract instance.
public final class ContractInfoQuery: Query<ContractInfo> {
    /// Create a new `ContractInfoQuery`.
    public init(
        contractId: ContractId? = nil
    ) {
        self.contractId = contractId
    }

    /// The contract ID for which information is requested.
    public var contractId: ContractId?

    /// Sets the contract ID for which information is requested.
    @discardableResult
    public func contractId(_ contractId: ContractId) -> Self {
        self.contractId = contractId

        return self
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.contractGetInfo = .with { proto in
                proto.header = header
                contractId?.toProtobufInto(&proto.contractID)
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query, _ deadline: TimeInterval)
        async throws -> Proto_Response
    {
        try await Proto_SmartContractServiceAsyncClient(channel: channel).getContractInfo(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .contractGetInfo(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `contractGetInfo`")
        }

        return try .fromProtobuf(proto.contractInfo)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try contractId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }

}
