// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Get the runtime bytecode for a smart contract instance.
public final class ContractBytecodeQuery: Query<Data> {
    /// Create a new `ContractBytecodeQuery`.
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
            proto.contractGetBytecode = .with { proto in
                proto.header = header
                contractId?.toProtobufInto(&proto.contractID)
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query) async throws -> Proto_Response {
        try await Proto_SmartContractServiceAsyncClient(channel: channel).contractGetBytecode(
            request, callOptions: applyGrpcHeader())
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .contractGetBytecodeResponse(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `contractGetBytecodeResponse`")
        }

        return proto.bytecode

    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try contractId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}
