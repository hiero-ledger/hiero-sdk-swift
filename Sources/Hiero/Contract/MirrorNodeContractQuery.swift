// SPDX-License-Identifier: Apache-2.0

import Foundation
import GRPC
import HieroProtobufs

/// MirrorNodeContractQuery returns a result from EVM execution such as cost-free execution of read-only smart
/// contract queries, gas estimation, and transient simulations of read-write operations.
public class MirrorNodeContractQuery: ValidateChecksums {
    /// The ID of the contract of which to get information.
    public var contractId: ContractId?
    /// The EVM address of the contract of which to get information.
    public var contractEvmAddress: EvmAddress?
    /// The ID of the sender account.
    public var sender: AccountId?
    /// The EVM address of the sender account.
    public var senderEvmAddress: EvmAddress?
    /// The getter for the call data.
    public var callData: Data? { _callData }
    /// The value.
    public var value: Int64?
    /// The gas limit.
    public var gasLimit: Int64?
    /// The gas price.
    public var gasPrice: Int64?
    /// The block number.
    public var blockNumber: UInt64?

    /// Set the ID of the contract.
    @discardableResult
    public func contractId(_ contractId: ContractId?) -> Self {
        self.contractId = contractId
        return self
    }

    /// Set the EVM address of the contract.
    @discardableResult
    public func contractEvmAddress(_ contractEvmAddress: EvmAddress?) -> Self {
        self.contractEvmAddress = contractEvmAddress
        return self
    }

    /// Set the ID of the sender account.
    @discardableResult
    public func sender(_ sender: AccountId?) -> Self {
        self.sender = sender
        return self
    }

    /// Set the EVM address of the sender account.
    @discardableResult
    public func senderEvmAddress(_ senderEvmAddress: EvmAddress?) -> Self {
        self.senderEvmAddress = senderEvmAddress
        return self
    }

    /// Sets the function to call, and the parameters to pass to the function.
    @discardableResult
    public func function(_ name: String, _ parameters: ContractFunctionParameters? = nil) -> Self {
        self._callData = (parameters ?? ContractFunctionParameters()).toBytes(name)
        return self
    }

    /// Set the value.
    @discardableResult
    public func value(_ value: Int64?) -> Self {
        self.value = value
        return self
    }

    /// Set the gas limit.
    @discardableResult
    public func gasLimit(_ gasLimit: Int64?) -> Self {
        self.gasLimit = gasLimit
        return self
    }

    /// Set the gas price.
    @discardableResult
    public func gasPrice(_ gasPrice: Int64?) -> Self {
        self.gasPrice = gasPrice
        return self
    }

    /// Set the block number.
    @discardableResult
    public func blockNumber(_ blockNumber: UInt64?) -> Self {
        self.blockNumber = blockNumber
        return self
    }

    /// Execute this MirrorNodeContractQuery.
    public func execute(_ client: Client) async throws -> String {
        let mirrorNetworkAddress = client.mirrorNetwork[0]
        let contractCallEndpoint = "/api/v1/contracts/call"

        /// Construct the URL.
        let url = URL(
            string: client.ledgerId == nil
                ? "http://" + mirrorNetworkAddress.split(separator: ":")[0] + ":8545" + contractCallEndpoint
                : "https://" + mirrorNetworkAddress + contractCallEndpoint)!

        /// Begin to construct the HTTP request.
        var request = URLRequest(url: url)
        request.httpBody = try JSONSerialization.data(withJSONObject: toJson(), options: [])
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        /// Send the request.
        let (data, response) = try await URLSession.shared.data(for: request)

        /// Make sure a good response was returned.
        guard let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        /// Verify the JSON response and return the result.
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

        guard let json = jsonObject as? [String: Any] else {
            throw HError.basicParse("Unable to decode JSON")
        }

        guard let result = json["result"] as? String else {
            throw HError.basicParse("No result was found for the contract call.")
        }

        return result.hasPrefix("0x") ? String(result.dropFirst(2)) : result
    }

    /// Convert the contents of this MirrorNodeContractQuery into a JSON format.
    public func toJson() throws -> [String: Any] {
        var json = [String: Any]()
        json["data"] = self.callData?.map { String(format: "%02x", $0) }.joined()
        json["from"] = try self.sender?.toSolidityAddress() ?? self.senderEvmAddress?.toString()
        json["to"] = try self.contractId?.toSolidityAddress() ?? self.contractEvmAddress?.toString()
        json["estimate"] = getEstimate()
        json["gasPrice"] = self.gasPrice
        json["gas"] = self.gasLimit
        json["blockNumber"] = self.blockNumber
        json["value"] = self.value

        return json
    }

    ////////////////
    /// INTERNAL ///
    ////////////////

    /// Should this MirrorNodeContractQuery get an estimate?
    internal func getEstimate() -> Bool {
        fatalError("MirrorNodeContractQuery does not have getEstimate() implemented!")
    }

    internal func validateChecksums(on ledgerId: LedgerId) throws {
        try contractId?.validateChecksums(on: ledgerId)
        try sender?.validateChecksums(on: ledgerId)
    }

    ///////////////
    /// PRIVATE ///
    ///////////////

    /// The call data.
    private var _callData: Data?
}
