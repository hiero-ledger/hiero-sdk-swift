// SPDX-License-Identifier: Apache-2.0

// MARK: - Client Configuration

/// Configuration structure for initializing a Client from JSON.
///
/// This struct supports flexible configuration where networks can be specified
/// either by name (mainnet, testnet, previewnet) or by custom address mappings.
///
/// ## Example Configuration
/// ```json
/// {
///   "network": "testnet",
///   "mirrorNetwork": "testnet",
///   "operator": {
///     "accountId": "0.0.123",
///     "privateKey": "302e..."
///   },
///   "shard": 0,
///   "realm": 0
/// }
/// ```
///
/// ## Custom Network Example
/// ```json
/// {
///   "network": {
///     "192.168.1.100:50211": "0.0.3",
///     "192.168.1.101:50211": "0.0.4"
///   },
///   "mirrorNetwork": ["192.168.1.100:5600"]
/// }
/// ```
///
/// ## Related Types
/// - `Client` - Initialized from this configuration via `fromConfig()`
/// - `NetworkSpecification` - Flexible network specification format
/// - `NetworkFactory` - Creates networks from specifications
/// - `Operator` - Transaction signing configuration
internal struct ClientConfig: Decodable {
    // MARK: - Properties
    
    /// Optional operator account for signing transactions
    internal let `operator`: Operator?
    
    /// Network configuration - either a predefined name or custom address map
    internal let network: ConsensusNetworkSpecification
    
    /// Mirror network configuration - either custom addresses or predefined name
    internal let mirrorNetwork: MirrorNetworkSpecification?
    
    /// Shard number (default: 0)
    internal let shard: UInt64
    
    /// Realm number (default: 0)
    internal let realm: UInt64
    
    // MARK: - Coding Keys

    private enum CodingKeys: CodingKey {
        case `operator`
        case network
        case mirrorNetwork
        case shard
        case realm
    }
    
    private enum OperatorKeys: CodingKey {
        case accountId
        case privateKey
    }
    
    // MARK: - Decoding

    /// Decodes client configuration from JSON.
    ///
    /// Handles conversion of:
    /// - String network names to NetworkSpecification
    /// - Custom network maps to NetworkSpecification
    /// - String account IDs to AccountId objects
    /// - Operator credentials with proper error handling
    ///
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: DecodingError if required fields are missing or invalid
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode operator (optional) - inline the logic
        if let operatorContainer = try? container.nestedContainer(
            keyedBy: OperatorKeys.self, 
            forKey: .operator
        ) {
            let accountIdStr = try operatorContainer.decode(String.self, forKey: .accountId)
            let privateKeyStr = try operatorContainer.decode(String.self, forKey: .privateKey)
            
            // Parse account ID with error wrapping
            let accountId: AccountId
            do {
                accountId = try AccountId.fromString(accountIdStr)
            } catch let error as HError {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: operatorContainer.codingPath + [OperatorKeys.accountId],
                        debugDescription: String(describing: error),
                        underlyingError: error
                    )
                )
            }
            
            // Parse private key with error wrapping
            let privateKey: PrivateKey
            do {
                privateKey = try PrivateKey.fromString(privateKeyStr)
            } catch let error as HError {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: operatorContainer.codingPath + [OperatorKeys.privateKey],
                        debugDescription: String(describing: error),
                        underlyingError: error
                    )
                )
            }
            
            `operator` = Operator(accountId: accountId, signer: .privateKey(privateKey))
        } else {
            `operator` = nil
        }

        // Decode network specification
        network = try container.decode(ConsensusNetworkSpecification.self, forKey: .network)

        // Decode mirror network specification (optional)
        mirrorNetwork = try container.decodeIfPresent(MirrorNetworkSpecification.self, forKey: .mirrorNetwork)
        
        // Decode shard and realm (with defaults)
        shard = try container.decodeIfPresent(UInt64.self, forKey: .shard) ?? 0
        realm = try container.decodeIfPresent(UInt64.self, forKey: .realm) ?? 0
    }
}

