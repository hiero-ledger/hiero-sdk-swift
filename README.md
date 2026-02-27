# Hiero Swift SDK

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/hiero-ledger/hiero-sdk-swift/badge)](https://scorecard.dev/viewer/?uri=github.com/hiero-ledger/hiero-sdk-swift)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/10697/badge)](https://bestpractices.coreinfrastructure.org/projects/10697)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

The Swift SDK for interacting with [Hiero](https://hiero.org)-based networks.

<sub>Maintained with ❤️ by <a href="https://www.hashgraph.com/" target="_blank">Hashgraph</a> and the <a href="https://hiero.org" target="_blank">Hiero</a> community.</sub>

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Examples](#examples)
- [Development](#development)
- [Testing](#testing)
- [Contributing](#contributing)
- [Community](#community)
- [License](#license)

---

## Requirements

| Platform | Minimum Version         |
|----------|-------------------------|
| Swift    | 5.6+ (6.0+ recommended) |
| macOS    | 10.15+ (Catalina, 2019) |
| iOS      | 13+ (2019)              |

> ⚠️ **Deprecation Notice:** Swift 5.x support is deprecated and will be removed in a future release. Please migrate to Swift 6.0+.

---

## Installation

Add the Hiero SDK to your Swift package dependencies:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/hiero-ledger/hiero-sdk-swift.git", from: "0.36.0")
]
```

For Xcode projects, see Apple's guide on [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app).

---

## Quick Start

```swift
import Hiero

// Connect to a Hiero network (testnet, mainnet, etc.)
let client = Client.forTestnet()

// Query the balance of an account
let balance = try await AccountBalanceQuery()
    .accountId(AccountId("0.0.1001")!)
    .execute(client)

print("Balance: \(balance.hbars)")
```

---

## Examples

The SDK includes example applications in the [Examples](./Examples) directory demonstrating accounts, tokens, consensus topics, files, smart contracts, scheduling, and more.

```bash
# Run an example
task example name=<ExampleName>

# For example:
task example name=CreateAccount
task example name=GetAccountBalance
```

---

## Development

### Required Tooling

| Tool | Source |
|------|--------|
| `protoc` | [Protocol Buffers](https://github.com/protocolbuffers/protobuf) compiler |
| `protoc-gen-swift` | [apple/swift-protobuf](https://github.com/apple/swift-protobuf) |
| `protoc-gen-grpc-swift` | [grpc/grpc-swift](https://github.com/grpc/grpc-swift) |
| `task` | [go-task/task](https://github.com/go-task/task) |
| `python3` | For proto generation scripts |

### Generating Protobufs

The `HieroProtobufs` module is entirely generated from the [hiero-consensus-node](https://github.com/hiero-ledger/hiero-consensus-node) protobufs.

```bash
# Fetch the latest protobufs and generate Swift code
task submodule:fetch

# Or fetch a specific version
task submodule:fetch proto=v0.61.0
```

---

## Testing

See [Tests/README.md](./Tests/README.md) for comprehensive testing documentation.

### Quick Start

```bash
# Unit tests (no network required)
swift test --filter HieroUnitTests

# Integration tests (requires environment configuration)
swift test --filter HieroIntegrationTests

# All tests
swift test

# Run a specific test
swift test --filter AccountCreateTransactionUnitTests/test_Serialize
```

### Environment Configuration

Create a `.env` file in the project root for integration tests:

```bash
# Required: Operator account credentials
HIERO_OPERATOR_ID=0.0.1234
HIERO_OPERATOR_KEY=302e020100300506032b657004220420...

# Environment type: testnet, previewnet, mainnet, or custom
HIERO_ENVIRONMENT_TYPE=testnet
```

### Testing with Solo

For local development and testing, we recommend using [Hiero Solo](https://github.com/hiero-ledger/solo). Solo provides a lightweight, local Hiero network running in Kubernetes.

```bash
# Solo environment configuration
HIERO_OPERATOR_ID=0.0.2
HIERO_OPERATOR_KEY=3030020100300706052b8104000a042204205bc004059ffa2943965d306f2c44d266255318b3775bacfec42a77ca83e998f2
HIERO_ENVIRONMENT_TYPE=custom
HIERO_CONSENSUS_NODES=127.0.0.1:50211,127.0.0.1:51211
HIERO_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4
HIERO_MIRROR_NODES=127.0.0.1:5600
```

> **Note:** Some tests that trigger address book updates require `/etc/hosts` entries for Kubernetes DNS names. See [Tests/README.md](./Tests/README.md#kubernetes-dns-configuration-required-for-node-update-tests) for details.

---

## Contributing

We welcome contributions from the community! Please refer to the [Hiero contribution guidelines](https://github.com/hiero-ledger/.github/blob/main/CONTRIBUTING.md) before getting started.

---

## Community

- **Discord**: Join the conversation on [LF Decentralized Trust Discord](https://discord.lfdecentralizedtrust.org/)
- **Governance**: Learn about roles and responsibilities in the [Hiero governance documentation](https://github.com/hiero-ledger/governance/blob/main/roles-and-groups.md#maintainers)

---

## License

This project is licensed under the **Apache License, Version 2.0**. See [LICENSE](LICENSE) for details.
