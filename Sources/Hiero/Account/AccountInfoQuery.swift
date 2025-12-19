// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// Get all the information about an account, including the balance.
///
/// This does not get the list of account records.
///
public final class AccountInfoQuery: Query<AccountInfo> {
    /// Create a new `AccountInfoQuery`.
    public init(
        accountId: AccountId? = nil
    ) {
        self.accountId = accountId
    }

    /// The account ID for which information is requested.
    public var accountId: AccountId?

    /// Sets the account ID for which information is requested.
    @discardableResult
    public func accountId(_ accountId: AccountId) -> Self {
        self.accountId = accountId

        return self
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.cryptoGetInfo = .with { proto in
                proto.header = header
                if let accountId = self.accountId {
                    proto.accountID = accountId.toProtobuf()
                }
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query, _ deadline: TimeInterval) async throws -> Proto_Response {
        try await Proto_CryptoServiceAsyncClient(channel: channel).getAccountInfo(
            request, callOptions: applyGrpcHeader(deadline: deadline))
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .cryptoGetInfo(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `cryptoGetInfo`")
        }

        return try .fromProtobuf(proto.accountInfo)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try accountId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}
