// SPDX-License-Identifier: Apache-2.0

import Foundation
import HieroProtobufs

public struct Endpoint {
    public var ipAddress: IPv4Address? = nil

    public var port: Int32 = 0

    public var domainName: String = ""

    public init(ipAddress: IPv4Address? = nil, port: Int32 = 0, domainName: String = "") {
        self.ipAddress = ipAddress
        self.port = port
        self.domainName = domainName
    }

    @discardableResult
    public mutating func address(_ ipAddress: IPv4Address) -> Self {
        self.ipAddress = ipAddress
        return self
    }

    @discardableResult
    public mutating func port(_ port: Int32) -> Self {
        self.port = port
        return self
    }

    @discardableResult
    public mutating func domainName(_ domainName: String) -> Self {
        self.domainName = domainName
        return self
    }

    public var description: String {
        guard !domainName.isEmpty else {
            return "\(ipAddress.debugDescription):\(port)"
        }
        return "\(domainName):\(port)"
    }
}
extension Endpoint: TryProtobufCodable {
    internal typealias Protobuf = Proto_ServiceEndpoint

    internal init(protobuf proto: Protobuf) throws {
        let ipAddress = IPv4Address(proto.ipAddressV4)

        var port = proto.port

        if proto.port == 0 || proto.port == 50111 {
            port = 50211
        }

        guard isValidDomainName(proto.domainName) else {
            throw HError(kind: .basicParse, description: "Invalid domain name format")
        }

        self.init(ipAddress: ipAddress, port: port, domainName: proto.domainName)
    }

    internal func toProtobuf() -> Protobuf {
        .with { proto in
            proto.ipAddressV4 = ipAddress?.rawValue ?? Data()
            proto.port = port
            proto.domainName = domainName
        }
    }
}

private func isValidDomainName(_ domainName: String) -> Bool {
    let pattern = "^((?!-)[A-Za-z0-9-]{1,63}(?<!-)\\.)+[A-Za-z]{2,6}$"
    let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    let range = NSRange(location: 0, length: domainName.utf16.count)
    return regex?.firstMatch(in: domainName, options: [], range: range) != nil
}
