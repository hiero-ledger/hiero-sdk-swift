import Foundation

internal final class Signer: Sendable {
    internal init(_ publicKey: PublicKey, _ signFunc: @Sendable @escaping (Data) -> Data) {
        self.publicKey = publicKey
        self.signFunc = signFunc
    }

    internal let publicKey: PublicKey
    fileprivate let signFunc: @Sendable (Data) -> Data

    internal static func privateKey(_ key: PrivateKey) -> Self {
        Self(key.publicKey, key.sign(_:))
    }

    internal func callAsFunction(_ message: Data) -> (PublicKey, Data) {
        (publicKey, signFunc(message))
    }
}
