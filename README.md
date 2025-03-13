# Hiero Swift SDK

The SDK for interacting with a Hiero based netwrok.

<sub>Maintained with ❤️ by <a href="https://launchbadge.com" target="_blank">LaunchBadge</a>, <a href="https://www.hashgraph.com/" target="_blank">Hashgraph</a>, and the Hedera community</sub>

## Usage

### Requirements

- Swift v5.6+
- MacOS v10.15+ (2019, Catalina)
- iOS 13+ (2019)

### Install

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/hiero-project/hiero-sdk-swift.git", from: "1.0.0")
]
```

See ["Adding Package Dependencies to Your App"](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app) for help on
adding a swift package to an Xcode project.

### Add to Code 

```swift
import Hiero

// connect to the Hedera network
let client = Client.forTestnet()

// query the balance of an account
let ab = try await AccountBalanceQuery()
    .accountId(AccountId("0.0.1001")!)
    .execute(client)

print("balance = \(ab.balance)")
```

See [examples](./Examples) for more usage.

## Development (HederaProtobufs)

HederaProtobufs is entirely generated. The protobufs repo will be migrated to Hiero [in near future](https://github.com/LFDT-Hiero/hiero/blob/main/transition.md).

### Required Tooling

protoc
protoc-gen-swift (from https://github.com/apple/swift-protobuf)
protoc-gen-grpc-swift (from https://github.com/grpc/grpc-swift)
task (from https://github.com/go-task/task)

### Fetch Submodule (Hedera-Protobufs)

Update [\protobuf](https://github.com/hashgraph/hedera-protobufs) submodule to latest changes.
```bash
## Fetch the latest version of the services submodule
## Note: Append "proto=<version>" to fetch a specific version
task submodule:fetch 

## Update the submodule to the latest version
task submodule:install

```

### Generate services
```bash
# cwd: `$REPO`
protoc --swift_opt=Visibility=Public --swift_opt=FileNaming=PathToUnderscores --swift_out=./Sources/HieroProtobufs/Services --proto_path=./Sources/HieroProtobufs/Protos/services Sources/HieroProtobufs/Protos/services/*.proto

# generate GRPC (if needed)
protoc --grpc-swift_opt=Visibility=Public,Server=false --grpc-swift_out=./Sources/HieroProtobufs/Services --proto_path=./Sources/HieroProtobufs/Protos/services Sources/HieroProtobufs/Protos/services/*.proto
```

###  Integration Tests

Before running the integration tests, an operator key, operator account id, and a network name must be set in an `.env` file. 

```bash
# Account that will pay query and transaction fees
TEST_OPERATOR_ID=
# Default private key to use to sign for all transactions and queries
TEST_OPERATOR_KEY=
# Network names: `"localhost"`, `"testnet"`, `"previewnet"`, `"mainnet"`
TEST_NETWORK_NAME=
```
```bash
# Run tests
$  swift test 
```

The networks testnet, previewnet, and mainnet are the related and publicly available [Hedera networks](https://docs.hedera.com/hedera/networks).

### Local Environment Testing

You can run tests through your localhost using the `hedera-local-node` service.
For instructions on how to set up and run local node, follow the steps in the [git repository](https://github.com/hashgraph/hedera-local-node).
The repo will be migrated to Hiero [in near future](https://github.com/LFDT-Hiero/hiero/blob/main/transition.md).
Once the local node is running in Docker, the appropriate `.env` values must be set:

```bash
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=3030020100300706052b8104000a042204205bc004059ffa2943965d306f2c44d266255318b3775bacfec42a77ca83e998f2
TEST_NETWORK_NAME=localhost
```

Lastly, run the tests using `swift test`
