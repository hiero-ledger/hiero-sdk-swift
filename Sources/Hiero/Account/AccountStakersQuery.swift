// SPDX-License-Identifier: Apache-2.0

import GRPC
import HieroProtobufs

/// Get all the accounts that are proxy staking to this account.
/// For each of them, give the amount currently staked.
public final class AccountStakersQuery: Query<[ProxyStaker]> {
    /// Create a new `AccountStakersQuery`.
    public init(
        accountId: AccountId? = nil
    ) {
        self.accountId = accountId
    }

    /// The account ID for which the records should be retrieved.
    public var accountId: AccountId?

    /// Sets the account ID for which the records should be retrieved.
    @discardableResult
    public func accountId(_ accountId: AccountId) -> Self {
        self.accountId = accountId

        return self
    }

    internal override func toQueryProtobufWith(_ header: Proto_QueryHeader) -> Proto_Query {
        .with { proto in
            proto.cryptoGetProxyStakers = .with { proto in
                proto.header = header
                if let accountId = self.accountId {
                    proto.accountID = accountId.toProtobuf()
                }
            }
        }
    }

    internal override func queryExecute(_ channel: GRPCChannel, _ request: Proto_Query) async throws -> Proto_Response {
        try await Proto_CryptoServiceAsyncClient(channel: channel).getStakersByAccountID(request)
    }

    internal override func makeQueryResponse(_ response: Proto_Response.OneOf_Response) throws -> Response {
        guard case .cryptoGetProxyStakers(let proto) = response else {
            throw HError.fromProtobuf("unexpected \(response) received, expected `cryptoGetProxyStakers`")
        }

        return try .fromProtobuf(proto.stakers.proxyStaker)
    }

    internal override func validateChecksums(on ledgerId: LedgerId) throws {
        try accountId?.validateChecksums(on: ledgerId)
        try super.validateChecksums(on: ledgerId)
    }
}
