// SPDX-License-Identifier: Apache-2.0

/// Represents all supported JSON-RPC method names.
///
/// Each case corresponds to a specific method string expected from incoming JSON-RPC requests.
/// Used to match requests with their appropriate handlers during routing.
internal enum JSONRPCMethod: String {
    case airdropToken
    case appendFile
    case approveAllowance
    case associateToken
    case burnToken
    case cancelAirdrop
    case claimToken
    case createAccount
    case contractByteCodeQuery
    case contractCallQuery
    case contractInfoQuery
    case createContract
    case createEthereumTransaction
    case createFile
    case createToken
    case createTopic
    case deleteAccount
    case deleteAllowance
    case deleteContract
    case deleteFile
    case deleteToken
    case deleteTopic
    case dissociateToken
    case executeContract
    case freezeToken
    case generateKey
    case getAccountBalance
    case getAccountInfo
    case getTokenInfo
    case grantTokenKyc
    case mintToken
    case pauseToken
    case rejectToken
    case reset
    case revokeTokenKyc
    case setOperator
    case setup
    case submitTopicMessage
    case transferCrypto
    case unfreezeToken
    case unpauseToken
    case updateAccount
    case updateContract
    case updateFile
    case updateTokenFeeSchedule
    case updateToken
    case updateTopic
    case wipeToken
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
