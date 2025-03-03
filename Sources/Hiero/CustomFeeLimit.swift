import Foundation
import HieroProtobufs

/// A maximum custom fee that the user is willing to pay.
///
/// This message is used to specify the maximum custom fee that given user is
/// willing to pay.
public struct CustomFeeLimit {
    /// Fee charged by the node for this functionality.
    public var payerId: AccountId

    /// The maximum fees that the user is willing to pay for the message.
    public var customFees: [CustomFixedFee]

    ///
    /// - Parameters:
    ///   - payerId: AccountId
    ///   - customFees: [CustomFixedFee]
    public init(payerId: AccountId, customFees: [CustomFixedFee]) {
        self.payerId = payerId
        self.customFees = customFees
    }
}

extension CustomFeeLimit: Equatable {
    public static func == (lhs: CustomFeeLimit, rhs: CustomFeeLimit) -> Bool {
        lhs.payerId == rhs.payerId && lhs.customFees == rhs.customFees
    }
}

extension CustomFeeLimit: TryProtobufCodable {
    internal typealias Protobuf = Proto_CustomFeeLimit

    internal init(protobuf proto: Protobuf) throws {
        self.init(
            payerId: try AccountId.fromProtobuf(proto.accountID),
            customFees: proto.fees.map { proto in
                CustomFixedFee(
                    FixedFee(
                        amount: UInt64(truncatingIfNeeded: proto.amount),
                        denominatingTokenId: proto.hasDenominatingTokenID
                            ? .fromProtobuf(proto.denominatingTokenID) : nil
                    ))
            }
        )
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.accountID = payerId.toProtobuf()
            proto.fees = customFees.map { fee in
                .with { proto in
                    proto.amount = Int64(fee.amount)
                    if let tokenId = fee.denominatingTokenId {
                        proto.denominatingTokenID = tokenId.toProtobuf()
                    }
                }
            }
        }
    }
}
