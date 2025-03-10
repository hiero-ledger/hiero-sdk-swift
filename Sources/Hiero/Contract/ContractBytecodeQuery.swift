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
        try await Proto_SmartContractServiceAsyncClient(channel: channel).contractGetBytecode(request)
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
