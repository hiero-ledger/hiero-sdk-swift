// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

/// The response containing the estimated transaction fees.
///
/// All properties are immutable (`@immutable` in the specification).
public struct FeeEstimateResponse {
    /// The mode that was used to calculate the fees.
    /// Immutable after initialization.
    public let mode: FeeEstimateMode

    /// The network fee component which covers the cost of gossip, consensus,
    /// signature verifications, fee payment, and storage.
    /// Immutable after initialization.
    public let networkFee: NetworkFee

    /// The node fee component which is to be paid to the node that submitted the
    /// transaction to the network.
    /// Immutable after initialization.
    public let nodeFee: FeeEstimate

    /// The service fee component which covers execution costs, state saved in the
    /// Merkle tree, and additional costs to the blockchain storage.
    /// Immutable after initialization.
    public let serviceFee: FeeEstimate

    /// An array of strings for any caveats (e.g., ["Fallback to worst-case due to missing state"]).
    /// Immutable after initialization. The array and its contents cannot be modified.
    public let notes: [String]

    /// The sum of the network, node, and service subtotals in tinycents.
    /// Immutable after initialization.
    public let total: UInt64

    internal init(
        mode: FeeEstimateMode,
        networkFee: NetworkFee,
        nodeFee: FeeEstimate,
        serviceFee: FeeEstimate,
        notes: [String],
        total: UInt64
    ) {
        self.mode = mode
        self.networkFee = networkFee
        self.nodeFee = nodeFee
        self.serviceFee = serviceFee
        self.notes = notes
        self.total = total
    }
}

extension FeeEstimateResponse: TryProtobufCodable {
    internal typealias Protobuf = Com_Hedera_Mirror_Api_Proto_FeeEstimateResponse

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            mode: try .fromProtobuf(proto.mode),
            networkFee: try .fromProtobuf(proto.network),
            nodeFee: try .fromProtobuf(proto.node),
            serviceFee: try .fromProtobuf(proto.service),
            notes: proto.notes,
            total: proto.total
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.mode = mode.toProtobuf()
            proto.network = networkFee.toProtobuf()
            proto.node = nodeFee.toProtobuf()
            proto.service = serviceFee.toProtobuf()
            proto.notes = notes
            proto.total = total
        }
    }
}

