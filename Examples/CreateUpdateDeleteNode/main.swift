// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero
import Network
import SwiftDotenv

@main
internal enum Program {
    internal static func main() async throws {
        let env = try Dotenv.load()
        let client = try Client.forName(env.networkName)

        // Set operator account
        client.setOperator(env.operatorAccountId, env.operatorKey)

        // Transaction parameters
        let accountId = try AccountId.fromString("0.0.999")
        let description = "This is a description of the node."
        let newDescription = "This is new a description of the node."
        let ipAddressV4 = "127.0.0.1"
        let port: Int32 = 50211
        let grpcProxyIpAddressV4 = "127.0.0.1"
        let grpcProxyPort: Int32 = 443
        let gossipEndpoint = Endpoint(ipAddress: IPv4Address(ipAddressV4), port: port, domainName: "")
        let gossipEndpoints = [gossipEndpoint]
        let serviceEndpoint = Endpoint(ipAddress: IPv4Address(ipAddressV4), port: port, domainName: "")
        let serviceEndpoints = [serviceEndpoint]
        let gossipCaCertificate = byteStringToData(
            "48,130,4,12,48,130,2,116,160,3,2,1,2,2,1,1,48,13,6,9,42,134,72,134,247,13,1,1,12,5,0,48,18,49,16,48,14,6,3,85,4,3,19,7,115,45,110,111,100,101,50,48,36,23,13,50,53,48,55,49,48,48,50,48,48,50,57,90,24,19,50,49,50,53,48,55,49,48,48,50,48,48,50,57,46,51,53,51,90,48,18,49,16,48,14,6,3,85,4,3,19,7,115,45,110,111,100,101,50,48,130,1,162,48,13,6,9,42,134,72,134,247,13,1,1,1,5,0,3,130,1,143,0,48,130,1,138,2,130,1,129,0,202,134,83,49,229,213,32,84,67,122,225,178,56,221,24,242,65,59,231,238,31,58,39,229,248,179,160,148,167,176,95,127,120,121,239,214,103,149,21,124,21,240,184,204,59,29,45,31,112,85,15,174,51,78,111,255,54,254,102,11,222,58,94,245,30,213,221,220,184,203,6,122,48,43,164,99,89,31,104,48,119,125,244,233,167,17,62,179,220,88,149,243,177,211,164,13,67,122,220,200,87,112,198,21,52,152,120,6,131,126,52,235,121,21,85,9,107,174,143,138,231,164,16,45,97,111,200,176,163,182,151,87,171,74,76,221,176,61,62,55,125,107,18,91,222,194,227,166,47,70,105,241,74,103,242,10,226,41,222,233,77,229,143,164,156,206,49,161,4,212,140,127,226,201,123,239,97,216,48,141,218,197,37,96,41,63,244,216,118,145,206,249,120,105,186,104,31,135,39,186,179,210,161,24,56,203,230,30,35,58,147,43,11,46,248,243,78,96,114,241,102,218,5,67,154,47,81,152,149,169,240,184,178,47,239,10,132,248,86,162,231,41,155,7,60,30,2,109,6,104,210,196,165,68,187,61,142,152,227,37,13,91,142,5,234,35,157,139,2,96,41,178,143,159,135,132,203,11,22,123,8,252,54,120,20,70,157,4,108,175,23,45,82,167,182,225,168,207,116,214,55,151,105,249,87,30,236,235,252,94,32,173,74,118,4,149,67,134,115,1,47,75,213,207,191,67,74,199,241,108,138,134,178,35,102,47,170,209,113,62,66,20,239,183,11,177,128,206,150,133,122,176,123,211,80,153,123,2,68,244,207,115,152,253,150,232,139,191,219,238,47,35,86,160,95,8,27,13,171,211,110,82,175,55,2,3,1,0,1,163,103,48,101,48,18,6,3,85,29,19,1,1,255,4,8,48,6,1,1,255,2,1,1,48,32,6,3,85,29,37,1,1,255,4,22,48,20,6,8,43,6,1,5,5,7,3,1,6,8,43,6,1,5,5,7,3,2,48,14,6,3,85,29,15,1,1,255,4,4,3,2,1,6,48,29,6,3,85,29,14,4,22,4,20,69,45,83,136,93,9,82,61,158,2,114,62,234,147,118,188,251,54,67,60,48,13,6,9,42,134,72,134,247,13,1,1,12,5,0,3,130,1,129,0,32,68,77,174,86,153,130,62,118,62,204,151,154,172,83,119,249,135,165,23,161,82,230,134,215,107,8,88,166,138,147,28,91,210,91,238,247,11,13,245,167,234,108,46,113,111,17,249,126,47,232,217,182,125,91,5,62,26,240,91,45,103,187,108,26,105,157,83,239,175,69,67,77,62,192,12,231,173,180,167,62,45,188,97,4,31,158,202,109,225,128,118,73,80,185,17,222,180,185,147,254,160,50,105,160,202,77,163,72,14,166,237,79,29,35,135,146,138,255,211,125,45,204,163,19,140,136,193,146,139,209,82,27,21,175,200,234,109,164,127,168,135,15,136,37,231,184,70,218,62,152,56,79,140,46,224,11,151,43,109,111,189,177,54,127,24,147,59,84,132,187,33,69,78,85,116,50,63,222,180,47,115,70,70,159,119,124,133,209,116,31,53,172,73,4,44,90,97,4,235,218,103,206,215,39,193,91,57,125,15,209,83,119,186,201,144,176,189,71,74,62,127,113,213,1,150,194,111,154,163,123,1,77,0,176,116,3,145,164,154,118,129,101,70,87,144,250,126,232,228,136,25,10,216,147,5,156,217,120,215,212,43,167,75,77,3,232,23,68,120,5,201,64,166,92,67,52,100,182,242,117,187,172,243,30,51,74,79,199,231,70,51,152,43,1,22,167,23,64,104,217,240,18,130,43,88,9,189,138,140,214,5,78,239,169,241,241,105,217,209,176,44,97,205,111,89,131,21,43,134,89,97,251,1,151,17,164,30,5,122,64,169,50,36,199,110,216,60,249,136,94,195,234,91,165,88,35,192,103,222,195,157,229,85,113,147,229,109,211,170,144,119,63,184,208,218,198,220,192,17,0,123,202,133"
        )
        let grpcWebProxyEndpoint = Endpoint(
            ipAddress: IPv4Address(grpcProxyIpAddressV4), port: grpcProxyPort, domainName: "")
        let adminKey = try PrivateKey.fromString(
            "302e020100300506032b657004220420273389ed26af9c456faa81e9ae4004520130de36e4f534643b7081db21744496")

        // 1. Create a new node
        print("Creating a new node...")
        let createTransaction = try NodeCreateTransaction()
            .accountId(accountId)
            .description(description)
            .gossipEndpoints(gossipEndpoints)
            .serviceEndpoints(serviceEndpoints)
            .gossipCaCertificate(gossipCaCertificate!)
            .adminKey(.single(adminKey.publicKey))
            .grpcWebProxyEndpoint(grpcWebProxyEndpoint)
            .declineRewards(false)
            .freezeWith(client)
            .sign(adminKey)

        let createTransactionResponse = try await createTransaction.execute(client)
        let createTransactionReceipt = try await createTransactionResponse.getReceipt(client)
        let nodeId = createTransactionReceipt.nodeId
        print("Node create transaction status: \(createTransactionReceipt.status.description)")
        print("Node has been created successfully with node id: \(nodeId)")

        let addressBook = try await NodeAddressBookQuery().setFileId(FileId.addressBook).execute(client)
        for nodeAddress in addressBook.nodeAddresses {
            print("Node ID: \(nodeAddress.nodeId)")
            print("Node Account ID: \(nodeAddress.nodeAccountId)")
            print("Node Description: \(nodeAddress.description)")
        }

        // 2. Update the node
        print("Updating the node...")
        let updateTransaction = try NodeUpdateTransaction()
            .nodeId(nodeId)
            .description(newDescription)
            .gossipCaCertificate(gossipCaCertificate!)
            .grpcCertificateHash(
                byteArrayToData([
                    216,
                    190,
                    49,
                    148,
                    92,
                    216,
                    96,
                    54,
                    134,
                    166,
                    193,
                    53,
                    24,
                    27,
                    185,
                    169,
                    141,
                    37,
                    249,
                    211,
                    247,
                    50,
                    21,
                    198,
                    44,
                    14,
                    216,
                    72,
                    182,
                    131,
                    225,
                    12,
                    96,
                    200,
                    234,
                    42,
                    116,
                    228,
                    134,
                    199,
                    17,
                    227,
                    13,
                    32,
                    224,
                    9,
                    18,
                    198,
                ])!
            )
            .declineRewards(true)
            .freezeWith(client)
            .sign(adminKey)
        let updateTransactionResponse = try await updateTransaction.execute(client)
        let updateTransactionReceipt = try await updateTransactionResponse.getReceipt(client)
        print("Node update transaction status: \(updateTransactionReceipt.status.description)")

        let addressBook2 = try await NodeAddressBookQuery().setFileId(FileId.addressBook).execute(client)
        for nodeAddress in addressBook2.nodeAddresses {
            print("Node ID: \(nodeAddress.nodeId)")
            print("Node Account ID: \(nodeAddress.nodeAccountId)")
            print("Node Description: \(nodeAddress.description)")
        }

        // 3. Delete the node
        print("Deleting the node...")
        let deleteTransaction = try NodeDeleteTransaction()
            .nodeId(nodeId)
            .freezeWith(client)
            .sign(adminKey)
        let deleteTransactionResponse = try await deleteTransaction.execute(client)
        let deleteTransactionReceipt = try await deleteTransactionResponse.getReceipt(client)
        print("Node delete transaction status: \(deleteTransactionReceipt.status.description)")
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
