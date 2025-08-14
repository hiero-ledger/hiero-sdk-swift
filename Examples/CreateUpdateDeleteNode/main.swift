// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import HieroExampleUtilities
import Network
import SwiftDotenv

// Set the paths **HERE** for the json files provided by solo.
let nodeCreateConfigPath = "add/path/here"
let nodeUpdateConfigPath = "add/path/here"

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        // Set operator account
        client.setOperator(env.operatorAccountId, env.operatorKey)
        await client.setNetworkUpdatePeriod(nanoseconds: 1_000_000_000 * 1_000_000)

        // Before running this example, you should already have solo up and running,
        // as well as having run an `add-prepare` command, to ready solo for the new
        // node to be added as well as being provided with needed values for the
        // NodeCreateTransaction you will send to solo.

        // Load the node create configuration from solo.
        let cfg = try loadNodeCreateConfig(at: nodeCreateConfigPath)

        // Map JSON -> SDK types
        let accountId = try AccountId.fromString(cfg.newNode.accountId)

        // Endpoints
        let gossipEndpoints: [Endpoint] = try cfg.gossipEndpoints.map(endpointFrom)
        let grpcServiceEndpoints: [Endpoint] = try cfg.grpcServiceEndpoints.map(endpointFrom)

        // Certificates / hashes
        let signingCertDer = try dataFromCommaSeparatedBytes(cfg.signingCertDer)
        let tlsCertHash = Data(cfg.tlsCertHash.data)

        // Admin key
        let adminKey = try PrivateKey.fromString(cfg.adminKey)

        // Create the node
        print("Creating a new node\(cfg.newNode.name.map { " named \($0)" } ?? "") from \(configPath)...")

        let createTransaction = try NodeCreateTransaction()
            .accountId(accountId)
            .gossipEndpoints(gossipEndpoints)
            .serviceEndpoints(grpcServiceEndpoints)
            .gossipCaCertificate(signingCertDer)
            .grpcCertificateHash(tlsCertHash)
            .grpcWebProxyEndpoint(grpcServiceEndpoints[0])
            .adminKey(.single(adminKey.publicKey))
            .freezeWith(client)
            .sign(adminKey)

        let response = try await createTransaction.execute(client)
        let receipt = try await response.getReceipt(client)
        print("Node create receipt: \(receipt)")

        // Allow yourself five minutes to freeze solo and restart it with an `add-execute`.
        await Task.sleep(nanoseconds: 1_000_000_000 * 60 * 5)

        // Print off the address book to verify the creation of the new node.
        let addressBook = try await NodeAddressBookQuery().setFileId(FileId.addressBook).execute(client)
        for nodeAddress in addressBook.nodeAddresses {
            print("Node ID: \(nodeAddress.nodeId)")
            print("Node Account ID: \(nodeAddress.nodeAccountId)")
            print("Node Description: \(nodeAddress.description)")
        }

        // Load the node update configuration from solo.
        let updateCfg = try loadNodeUpdateConfig(at: nodeUpdateConfigPath)
        let updateInputs = try makeNodeUpdateInputs(from: updateCfg)

        // 2. Update the node
        print("Updating the node...")
        let updateTransaction = try NodeUpdateTransaction()
            .nodeId(1)
            .declineRewards(true)
            .freezeWith(client)
            .sign(updateInputs.adminKey)
        let updateTransactionResponse = try await updateTransaction.execute(client)
        let updateTransactionReceipt = try await updateTransactionResponse.getReceipt(client)
        print("Node update receipt: \(updateTransactionReceipt)")

        // Allow yourself five minutes to freeze solo and restart it with an `update-execute`.
        await Task.sleep(nanoseconds: 1_000_000_000 * 60 * 5)

        // Print off the address book to verify the update of the node.
        let addressBook2 = try await NodeAddressBookQuery().setFileId(FileId.addressBook).execute(client)
        for nodeAddress in addressBook2.nodeAddresses {
            print("Node ID: \(nodeAddress.nodeId)")
            print("Node Account ID: \(nodeAddress.nodeAccountId)")
            print("Node Description: \(nodeAddress.description)")
        }
    }
}

extension Environment {
    /// Account ID for the operator to use in this example.
    internal var operatorAccountId: AccountId {
        AccountId(self["OPERATOR_ID"]!.stringValue)!
    }

    /// Private key for the operator to use in this example.
    internal var operatorKey: PrivateKey {
        PrivateKey(self["OPERATOR_KEY"]!.stringValue)!
    }

    /// The name of the hedera network this example should be ran against.
    ///
    /// Testnet by default.
    internal var networkName: String {
        self["HEDERA_NETWORK"]?.stringValue ?? "testnet"
    }
}

extension Data {
    internal init?<S: StringProtocol>(hexEncoded: S) {
        let chars = Array(hexEncoded.utf8)
        // note: hex check is done character by character
        let count = chars.count

        guard count % 2 == 0 else {
            return nil
        }

        var arr: [UInt8] = Array()
        arr.reserveCapacity(count / 2)

        for idx in stride(from: 0, to: hexEncoded.count, by: 2) {
            // swiftlint complains about the length of these if they're less than 4 characters
            // that'd be fine and all, but `low` is still only 3 characters.
            guard let highNibble = hexVal(UInt8(chars[idx])), let lowNibble = hexVal(UInt8(chars[idx + 1])) else {
                return nil
            }

            arr.append(highNibble << 4 | lowNibble)
        }

        self.init(arr)
    }
}

private func hexVal(_ char: UInt8) -> UInt8? {
    // this would be a very clean function if swift had a way of doing ascii-charcter literals, but it can't.
    let ascii0: UInt8 = 0x30
    let ascii9: UInt8 = ascii0 + 9
    let asciiUppercaseA: UInt8 = 0x41
    let asciiUppercaseF: UInt8 = 0x46
    let asciiLowercaseA: UInt8 = asciiUppercaseA | 0x20
    let asciiLowercaseF: UInt8 = asciiUppercaseF | 0x20
    switch char {
    case ascii0...ascii9:
        return char - ascii0
    case asciiUppercaseA...asciiUppercaseF:
        return char - asciiUppercaseA + 10
    case asciiLowercaseA...asciiLowercaseF:
        return char - asciiLowercaseA + 10
    default:
        return nil
    }
}

func byteStringToPEMData(_ byteString: String, label: String = "CERTIFICATE") -> Data? {
    // Step 1: Convert comma-separated decimal string to Data
    let components =
        byteString
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }

    var rawData = Data(capacity: components.count)
    for byteStr in components {
        guard let byte = UInt8(byteStr) else {
            print("Invalid byte value: \(byteStr)")
            return nil
        }
        rawData.append(byte)
    }

    // Step 2: Base64 encode the raw data
    let base64String = rawData.base64EncodedString()

    // Step 3: Split base64 string into 64-character lines
    var pemBody = ""
    var index = base64String.startIndex
    while index < base64String.endIndex {
        let nextIndex =
            base64String.index(index, offsetBy: 64, limitedBy: base64String.endIndex) ?? base64String.endIndex
        pemBody += base64String[index..<nextIndex] + "\n"
        index = nextIndex
    }

    // Step 4: Add PEM headers
    let pemString = "-----BEGIN \(label)-----\n" + pemBody + "-----END \(label)-----\n"
    return pemString.data(using: .utf8)
}

func byteStringToData(_ byteString: String) -> Data? {
    let components =
        byteString
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    var data = Data(capacity: components.count)

    for byteStr in components {
        guard let byte = UInt8(byteStr) else {
            print("Invalid byte value: \(byteStr)")
            return nil
        }
        data.append(byte)
    }

    return data
}

func byteArrayToData(_ bytes: [Int]) -> Data? {
    var data = Data(capacity: bytes.count)

    for byte in bytes {
        guard (0...255).contains(byte) else {
            print("Invalid byte value: \(byte). Must be in 0...255.")
            return nil
        }
        data.append(UInt8(byte))
    }

    return data
}
