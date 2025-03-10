// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Get all the records for an account for any transfers into it and out of it,
/// that were above the threshold, during the last 25 hours.
public final class AccountRecordsQuery: Query<[TransactionRecord]> {
    /// Create a new `AccountRecordsQuery`.
    public init(
        accountId: AccountId? = nil
    ) {
        self.accountId = accountId
    }

    /// The account ID for which records are requested.
    public var accountId: AccountId?

    /// Sets the account ID for which records are requested.
    @discardableResult
    public func accountId(_ accountId: AccountId) -> Self {
        self.accountId = accountId

        return self
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.cryptoGetAccountRecords = .with { proto in
                proto.header = header
                if let accountId = self.accountId {
                    proto.accountID = accountId.toProtobuf()
                }
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query) async throws -> Proto_Response {
        try await Proto_CryptoServiceAsyncClient(channel: channel).getAccountRecords(request)
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .cryptoGetAccountRecords(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `cryptoGetAccountRecords`")
        }

        return try .fromProtobuf(proto.records)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try accountId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}
