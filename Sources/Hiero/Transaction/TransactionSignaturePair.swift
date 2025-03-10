// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

extension Transaction {
    internal struct SignaturePair {
        internal let signature: Data
        internal let publicKey: PublicKey

        internal init(_ pair: (PublicKey, Data)) {
            publicKey = pair.0
            signature = pair.1
        }
    }
}

extension Transaction.SignaturePair: ToProtobuf {
    internal func toProtobuf() -> Proto_SignaturePair {
        .with { proto in
            switch publicKey {
            case _ where publicKey.isEcdsa():
                proto.ecdsaSecp256K1 = signature

            case _ where publicKey.isEd25519():
                proto.ed25519 = signature

            default:
                fatalError("Unknown public key kind")
            }
            proto.pubKeyPrefix = publicKey.toBytesRaw()
        }
    }
}
