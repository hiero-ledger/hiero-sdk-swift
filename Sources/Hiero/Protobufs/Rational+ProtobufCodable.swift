import HieroProtobufs
import NumberKit

extension Rational: ProtobufCodable where T == Int64 {
    internal typealias Protobuf = Proto_Fraction

    internal init(protobuf proto: Protobuf) {
        self.init(proto.numerator, proto.denominator)
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.numerator = self.numerator
            proto.denominator = self.denominator
        }
    }
}
