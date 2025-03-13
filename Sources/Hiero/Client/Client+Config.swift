// SPDX-License-Identifier: Apache-2.0

internal enum NetworkName: Decodable {
    case mainnet
    case testnet
    case previewnet
}

private struct ConfigOperator: Decodable {
    private enum CodingKeys: CodingKey {
        case accountId
        case privateKey
    }

    fileprivate let accountId: AccountId
    fileprivate let privateKey: PrivateKey
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let privateKeyStr = try container.decode(String.self, forKey: .privateKey)

        do {
            privateKey = try PrivateKey.fromString(privateKeyStr)
        } catch let error as HError {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: container.codingPath + [CodingKeys.privateKey],
                    debugDescription: String(describing: error),
                    underlyingError: error
                )
            )
        }

        let accountIdStr = try container.decode(String.self, forKey: .accountId)

        do {
            accountId = try AccountId.fromString(accountIdStr)
        } catch let error as HError {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: container.codingPath + [CodingKeys.accountId],
                    debugDescription: String(describing: error),
                    underlyingError: error
                )
            )
        }
    }
}

extension Operator {
    fileprivate init(_ configOperator: ConfigOperator) {
        self.accountId = configOperator.accountId
        self.signer = .privateKey(configOperator.privateKey)
    }
}

internal enum Either<Left, Right> {
    case left(Left)
    case right(Right)
}

extension Either: Decodable where Left: Decodable, Right: Decodable {
    internal init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let res = try? container.decode(Left.self) {
            self = .left(res)
            return
        }

        if let res = try? container.decode(Right.self) {
            self = .right(res)
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Data corrupted: No option in untagged container decoded successfully"
        )
    }
}

extension Client {
    internal struct Config: Decodable {
        internal let `operator`: Operator?
        internal let network: Either<[String: AccountId], NetworkName>
        internal let mirrorNetwork: Either<[String], NetworkName>?

        private enum CodingKeys: CodingKey {
            case `operator`
            case network
            case mirrorNetwork
        }

        internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            `operator` = try container.decodeIfPresent(ConfigOperator.self, forKey: .operator).map(Operator.init(_:))

            let networkStr = try container.decode(Either<[String: String], NetworkName>.self, forKey: .network)

            switch networkStr {
            case .left(let map):
                do {
                    network = try .left(map.mapValues(AccountId.init(parsing:)))
                } catch let error as HError {
                    throw DecodingError.dataCorruptedError(
                        forKey: .network, in: container, debugDescription: String(describing: error))
                }
            case .right(let name):
                network = .right(name)
            }

            mirrorNetwork = try container.decodeIfPresent(Either<[String], NetworkName>.self, forKey: .mirrorNetwork)
        }
    }
}
