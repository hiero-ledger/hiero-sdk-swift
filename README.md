# Hiero Swift SDK

The SDK for interacting with a Hiero based network.

<sub>Maintained with ❤️ by <a href="https://launchbadge.com" target="_blank">LaunchBadge</a>, <a href="https://www.hashgraph.com/" target="_blank">Hashgraph</a>, and the Hiero community</sub>

## Usage

### Requirements

- Swift v5.6+
- MacOS v10.15+ (2019, Catalina)
- iOS 13+ (2019)

### Install

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/hiero-project/hiero-sdk-swift.git", from: "0.36.0")
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

## Development (HieroProtobufs)

HieroProtobufs are entirely generated.

### Required Tooling

protoc
protoc-gen-swift (from https://github.com/apple/swift-protobuf)
protoc-gen-grpc-swift (from https://github.com/grpc/grpc-swift)
task (from https://github.com/go-task/task)
openSSL 3.4 (from https://openssl-library.org/source/)

### Fetch Submodule and Generate Swift Protobufs (HieroProtobufs)

Update [\protobufs](https://github.com/hiero-ledger/hiero-consensus-node.git) submodule to latest changes.

```bash
# Fetch the latest version of the services submodule
# and generate swift code for Hiero protobufs and gRPC.
#
# Note: Append "proto=vX.Y.Z" to fetch a specific version
task submodule:fetch 

# e.g. move submodule to v0.61.0 tag
task submodule:fetch proto=v0.61.0
```

### Examples
See [examples](./Examples) for more usage.

```bash
# Run an example
$  task example name=<example>

# e.g CreateAccount
$  task example name=CreateAccount

```

### Testing
See [HieroTests](./Tests/HieroTests) and [HieroE2ETests](./Tests/HieroE2ETests)

Before running the integration tests (e2e)– an operator key, operator account id, and a network name must be set in an `.env` file. Unit tests do not require `.env` to be executed.

```bash
# Account that will pay query and transaction fees
TEST_OPERATOR_ID=
# Default private key to use to sign for all transactions and queries
TEST_OPERATOR_KEY=
# Network names: `"localhost"`, `"testnet"`, `"previewnet"`, `"mainnet"`
TEST_NETWORK_NAME=
```

```bash
# Run all unit and e2e tests
$  swift test

# Run specific tests
$  swift test --filter <subclass>/<testMethod>

# e.g. AccountCreateTransactionTests/testSerialize (unit test)
$  swift test --filter AccountCreateTransactionTests/testSerialize

# e.g. AccountCreate/testInitialBalanceAndKey (e2e test) 
$  swift test --filter AccountCreate/testInitialBalanceAndKey
```

The networks testnet, previewnet, and mainnet are the related and publicly available [Hedera networks](https://docs.hedera.com/hedera/networks).


### Local Environment Testing

You can run tests through your localhost using the `hiero-local-node` service.
For instructions on how to set up and run local node, follow the steps in the [git repository](https://github.com/hiero-ledger/hiero-local-node).
Once the local node is running in Docker, the appropriate `.env` values must be set:

```bash
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=3030020100300706052b8104000a042204205bc004059ffa2943965d306f2c44d266255318b3775bacfec42a77ca83e998f2
TEST_NETWORK_NAME=localhost
```

Lastly, run the tests using `swift test`
