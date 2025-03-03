import Foundation
import HieroProtobufs

/// A fixed fee to assess for each token transfer, regardless of the
/// amount transferred.<br/>
/// This fee type describes a fixed fee for each transfer of a token type.
///
/// The fee SHALL be charged to the `sender` for the token transfer
/// transaction.<br/>
/// This fee MAY be assessed in HBAR, the token type transferred, or any
/// other token type, as determined by the `denominating_token_id` field.
public struct CustomFixedFee: CustomFee, Equatable {
    /// The amount of HBAR or other token described by this `FixedFee` SHALL
    /// be charged to the transction payer for each message submitted to a
    /// topic that assigns this consensus custom fee.
    public var amount: UInt64

    /// The shard, realm, number of the tokens.
    public var denominatingTokenId: TokenId?

    /// The account to receive the custom fee.
    public var feeCollectorAccountId: AccountId?

    /// True if all collectors are exempt from fees, false otherwise.
    public var allCollectorsAreExempt: Bool = false

    public init(
        _ amount: UInt64 = 0, _ feeCollectorAccountId: AccountId? = nil, _ denominatingTokenId: TokenId? = nil,
        _ allCollectorsAreExempt: Bool = false
    ) {
        self.amount = amount
        self.denominatingTokenId = denominatingTokenId
        self.feeCollectorAccountId = feeCollectorAccountId
        self.allCollectorsAreExempt = allCollectorsAreExempt
    }

    public init(
        _ fixedFee: FixedFee?, _ feeCollectorAccountId: AccountId? = nil,
        _ allCollectorsAreExempt: Bool = false
    ) {
        self.amount = fixedFee?.amount ?? 0
        self.denominatingTokenId = fixedFee?.denominatingTokenId
        self.feeCollectorAccountId = feeCollectorAccountId
        self.allCollectorsAreExempt = allCollectorsAreExempt
    }

    public mutating func allCollectorsAreExempt(_ allCollectorsAreExempt: Bool) {}

    internal func toTopicFeeProtobuf() -> Proto_FixedCustomFee {
        Proto_FixedCustomFee.with { proto in
            if let feeCollectorAccountId = feeCollectorAccountId {
                proto.feeCollectorAccountID = feeCollectorAccountId.toProtobuf()
            }

            proto.fixedFee = .with { proto in
                proto.amount = Int64(truncatingIfNeeded: amount)
            }

            if let denominatingTokenId = denominatingTokenId {
                proto.fixedFee = Proto_FixedFee.with { proto in
                    proto.amount = Int64(truncatingIfNeeded: amount)
                    proto.denominatingTokenID = denominatingTokenId.toProtobuf()
                }
            }
        }
    }
}

extension CustomFixedFee: TryProtobufCodable {
    internal typealias Protobuf = Proto_FixedCustomFee

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            UInt64(proto.fixedFee.amount),
            proto.hasFeeCollectorAccountID
                ? try AccountId.fromProtobuf(proto.feeCollectorAccountID) : nil,
            proto.fixedFee.hasDenominatingTokenID
                ? .fromProtobuf(proto.fixedFee.denominatingTokenID) : nil
        )
    }

    internal func toProtobuf() -> Protobuf {
        Proto_FixedCustomFee.with { proto in
            if let feeCollectorAccountId = feeCollectorAccountId {
                proto.feeCollectorAccountID = feeCollectorAccountId.toProtobuf()
            }

            proto.fixedFee = .with { fee in
                fee.amount = Int64(amount)
                if let tokenId = denominatingTokenId {
                    fee.denominatingTokenID = tokenId.toProtobuf()
                }
            }

        }
    }
}
