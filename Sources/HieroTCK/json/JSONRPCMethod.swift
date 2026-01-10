// SPDX-License-Identifier: Apache-2.0

/// Represents all supported JSON-RPC method names.
///
/// Each case corresponds to a specific method string expected from incoming JSON-RPC requests.
/// Used to match requests with their appropriate handlers during routing.
internal enum JSONRPCMethod: String {
    case airdropToken = "airdropToken"
    case appendFile = "appendFile"
    case approveAllowance = "approveAllowance"
    case associateToken = "associateToken"
    case burnToken = "burnToken"
    case cancelAirdrop = "cancelAirdrop"
    case claimToken = "claimToken"
    case createAccount = "createAccount"
    case createFile = "createFile"
    case createToken = "createToken"
    case createTopic = "createTopic"
    case deleteAccount = "deleteAccount"
    case deleteAllowance = "deleteAllowance"
    case deleteFile = "deleteFile"
    case deleteToken = "deleteToken"
    case deleteTopic = "deleteTopic"
    case dissociateToken = "dissociateToken"
    case freezeToken = "freezeToken"
    case generateKey = "generateKey"
    case grantTokenKyc = "grantTokenKyc"
    case mintToken = "mintToken"
    case pauseToken = "pauseToken"
    case rejectToken = "rejectToken"
    case reset = "reset"
    case revokeTokenKyc = "revokeTokenKyc"
    case setOperator = "setOperator"
    case setup = "setup"
    case submitTopicMessage = "submitTopicMessage"
    case transferCrypto = "transferCrypto"
    case unfreezeToken = "unfreezeToken"
    case unpauseToken = "unpauseToken"
    case updateAccount = "updateAccount"
    case updateFile = "updateFile"
    case updateTokenFeeSchedule = "updateTokenFeeSchedule"
    case updateToken = "updateToken"
    case updateTopic = "updateTopic"
    case wipeToken = "wipeToken"
    case unsupported

    /// Attempts to parse a string into a corresponding `JSONRPCMethod` enum value.
    ///
    /// If the method name is not recognized, `.unsupported` is returned to allow graceful fallback handling.
    ///
    /// - Parameters:
    ///   - method: The method string from the incoming JSON-RPC request.
    /// - Returns: A `JSONRPCMethod` value, or `.unsupported` if not recognized.
    internal static func method(named method: String) -> JSONRPCMethod {
        JSONRPCMethod(rawValue: method) ?? .unsupported
    }
}
