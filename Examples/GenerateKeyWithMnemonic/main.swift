// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

@main
internal enum Program {
    internal static func main() async throws {
        do {
            let mnemonic = Mnemonic.generate24()
            let privateKey = try mnemonic.toPrivateKey()
            let publicKey = privateKey.publicKey

            print("24 word mnemonic: \(mnemonic)")
            print("private key = \(privateKey)")
            print("public key = \(publicKey)")
        }

        do {
            let mnemonic = Mnemonic.generate12()
            let privateKey = try mnemonic.toPrivateKey()
            let publicKey = privateKey.publicKey

            print("12 word mnemonic: \(mnemonic)")
            print("private key = \(privateKey)")
            print("public key = \(publicKey)")
        }
    }
}
