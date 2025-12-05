# Test Configuration Guide

This guide explains how to configure the testing framework for different environments.

## Quick Start

**Simplest setup** (using testnet):

```bash
# .env
TEST_OPERATOR_ID=0.0.YOUR_ACCOUNT_ID
TEST_OPERATOR_KEY=YOUR_PRIVATE_KEY
```

That's it! The framework will use sensible defaults.

## Configuration Methods

There are three ways to configure tests, in order of precedence:

1. **Environment Variables** (`.env` file) - Most common
2. **Test Profiles** - Predefined configurations
3. **Programmatic** - Builder pattern in code

## Environment Variables

### Required - Operator Credentials

These are **required** for integration tests:

| Variable | Description | Example |
|----------|-------------|---------|
| `TEST_OPERATOR_ID` | Operator account ID | `0.0.1234` |
| `TEST_OPERATOR_KEY` | Operator private key | `302e020100300506032b657004220420...` |

**Getting Credentials:**
- **Testnet (Free)**: [portal.hedera.com](https://portal.hedera.com/)
- **Previewnet (Free)**: [portal.hedera.com](https://portal.hedera.com/)
- **Mainnet (Costs ℏ)**: Create account via wallet or exchange

### Optional - Network Selection

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `TEST_ENVIRONMENT_TYPE` | Network to connect to | Profile-dependent | `unit`, `local`, `testnet`, `previewnet`, `mainnet`, `ci`, `integration` |

**Network Types:**
- `unit` - No network (unit tests only)
- `local` - Local Hedera node (127.0.0.1:50211)
- `testnet` - Hedera Testnet (default for most profiles)
- `previewnet` - Hedera Previewnet
- `mainnet` - Hedera Mainnet (⚠️ costs real money)
- `ci` - CI environment (usually testnet)
- `integration` - Custom integration environment

### Optional - Custom Network Nodes

For local or custom networks:

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `TEST_CONSENSUS_NODES` | Comma-separated consensus node addresses | Local: `127.0.0.1:50211` | `127.0.0.1:50211,192.168.1.100:50211` |
| `TEST_CONSENSUS_NODE_ACCOUNT_IDS` | Comma-separated account IDs (must match node count) | Local: `0.0.3` | `0.0.3,0.0.4` |
| `TEST_MIRROR_NODES` | Comma-separated mirror node addresses | Local: `127.0.0.1:5600` | `mainnet.mirrornode.hedera.com:443` |

### Optional - Mirror Node Address Book

For environments where consensus nodes are discovered via mirror node (e.g., managed services):

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `TEST_MIRROR_NODES` | Comma-separated mirror nodes | Empty | `mainnet.mirrornode.hedera.com:443,backup.mirror.com:443` |

**Example:**

```bash
# .env
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
TEST_MIRROR_NODES=mainnet.mirrornode.hedera.com:443
# Do NOT set TEST_CONSENSUS_NODES (no explicit consensus nodes)
```

The framework automatically uses `Client.forMirrorNetwork()` when:
- Mirror nodes are specified (`TEST_MIRROR_NODES`), AND
- No consensus nodes are configured (no `TEST_CONSENSUS_NODES`)

This will:
1. Call `Client.forMirrorNetwork(["mainnet.mirrornode.hedera.com:443"])`
2. Query the mirror node's address book to discover consensus nodes
3. Set up the client with the discovered nodes

**When to use this:**
- Custom/managed Hedera networks
- Networks with dynamic node configurations
- When you only have access to mirror nodes

### Optional - Test Behavior

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `TEST_PROFILE` | Test profile to use | `development` | `quickLocal`, `fullLocal`, `ciUnit`, `ciIntegration`, `development` |
| `TEST_SKIP_SLOW` | Skip slow tests | `0` | `0`, `1` |
| `TEST_ENABLE_CLEANUP` | Enable resource cleanup | `1` | `0` (ephemeral networks), `1` (persistent) |
| `TEST_VERBOSE` | Verbose output | `0` | `0`, `1` |
| `TEST_MAX_DURATION` | Max test duration (seconds) | `300` | Any number |

## Test Profiles

Test profiles provide pre-configured settings for common scenarios.

### Available Profiles

| Profile | Environment | Cleanup | Use Case |
|---------|-------------|---------|----------|
| `quickLocal` | Unit | No | Quick unit tests on local machine |
| `fullLocal` | Local node | Yes | Full test suite on local Hedera node |
| `ciUnit` | Unit | No | Unit tests in CI (no network) |
| `ciIntegration` | CI/Ephemeral | No | Integration tests in CI with ephemeral network |
| `development` | Testnet/Custom | Yes | Integration tests in another environment |

### Using Profiles

**Via Environment Variable:**

```bash
TEST_PROFILE=ciIntegration
```

**Via Code:**

```swift
let config = try TestEnvironmentConfig.fromProfile(.development)
```

### Profile Behaviors

**`quickLocal`** - Fast unit tests
- No network connectivity
- No cleanup (no resources created)
- Snapshots disabled
- Fast timeouts (60s)

**`fullLocal`** - Complete local testing
- Uses local Hedera node (127.0.0.1:50211)
- Cleanup enabled
- All features enabled

**`ciUnit`** - CI unit tests
- No network connectivity
- Verbose logging
- Snapshots enabled

**`ciIntegration`** - CI integration tests
- Uses testnet or ephemeral network
- Cleanup disabled (network destroyed after tests)
- Verbose logging

**`development`** - Developer integration tests
- Uses testnet or custom network
- Cleanup enabled (avoid wasting HBAR)
- Balanced settings

## Configuration Examples

### 1. Local Development (Quick)

For fast iteration with unit tests only:

```bash
# .env
TEST_PROFILE=quickLocal
```

### 2. Local Development (Full)

Running integration tests against local node:

```bash
# .env
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e020100300506032b65700422042091132178e72057a1d7528025956fe39b0b847f200ab59b2fdd367017f3087137
TEST_PROFILE=fullLocal
```

### 3. Development Against Testnet

Most common for development:

```bash
# .env
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=YOUR_TESTNET_KEY
TEST_PROFILE=development
```

### 4. Development with Mirror Node Discovery

For custom/managed networks:

```bash
# .env
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=YOUR_KEY
TEST_PROFILE=development
TEST_MIRROR_NODES=custom.mirror.com:443,backup.mirror.com:443
# Mirror network will be used automatically (no consensus nodes configured)
```

### 5. CI Environment

```yaml
# .github/workflows/test.yml
env:
  TEST_PROFILE: ciIntegration
  TEST_OPERATOR_ID: ${{ secrets.TESTNET_OPERATOR_ID }}
  TEST_OPERATOR_KEY: ${{ secrets.TESTNET_OPERATOR_KEY }}
  TEST_ENABLE_CLEANUP: 0  # Ephemeral network
  TEST_VERBOSE: 1
```

## Programmatic Configuration

### Basic Setup

```swift
import HieroTestSupport

let config = try TestEnvironmentConfig.fromEnvironment()
let testEnv = try await IntegrationTestEnvironment.create(config: config)
```

### Custom Configuration

```swift
let config = TestEnvironmentConfig.builder()
    .type(.testnet)
    .operator(operatorConfig)
    .features(FeatureFlags(
        enableResourceCleanup: true,
        skipSlowTests: false
    ))
    .build()
```

### Mirror Network Configuration

```swift
let networkConfig = NetworkConfig(
    nodes: [:],  // Will be discovered via mirror node
    mirrorNodes: ["mainnet.mirrornode.hedera.com:443"],
    useMirrorNodeAddressBook: true
)

let config = TestEnvironmentConfig(
    type: .testnet,
    network: networkConfig,
    operator: operatorConfig,
    features: featureFlags,
    profile: .development
)
```

## Best Practices

### 1. Use `.env` for Credentials

**Never commit credentials to git!**

```bash
# .gitignore
.env
.env.*
!.env.example
```

### 2. Separate Environments

Use different accounts for different environments:

```bash
# .env.local
TEST_OPERATOR_ID=0.0.LOCAL_ACCOUNT
TEST_OPERATOR_KEY=LOCAL_KEY

# .env.testnet
TEST_OPERATOR_ID=0.0.TESTNET_ACCOUNT
TEST_OPERATOR_KEY=TESTNET_KEY
```

Then load with:
```bash
# Load testnet config
export $(cat .env.testnet | xargs)
swift test
```

### 3. Use Environment-Specific Profiles

```bash
# Local development - fast feedback
TEST_PROFILE=development
TEST_SKIP_SLOW=1

# CI - thorough testing (ephemeral network)
TEST_PROFILE=ciIntegration
TEST_VERBOSE=1
TEST_ENABLE_CLEANUP=0  # Network is destroyed after tests
```

### 4. Document Your Setup

Create a `tests/.env.example`:

```bash
# Copy this file to .env and fill in your values

# Operator (required)
TEST_OPERATOR_ID=0.0.YOUR_ACCOUNT_HERE
TEST_OPERATOR_KEY=YOUR_KEY_HERE

# Network (optional, defaults to testnet)
# TEST_ENVIRONMENT_TYPE=testnet

# Profile (optional, defaults to development)
TEST_PROFILE=development
```

### 5. Monitor Costs

```swift
// Track test costs if needed
func testOperationWithCosts() async throws {
    let startBalance = try await AccountBalanceQuery()
        .accountId(testEnv.operator.accountId)
        .execute(testEnv.client)
        .hbars
    
    // ... perform operations
    
    let endBalance = try await AccountBalanceQuery()
        .accountId(testEnv.operator.accountId)
        .execute(testEnv.client)
        .hbars
    
    let cost = startBalance - endBalance
    print("Test cost: \(cost) HBAR")
}
```

### 6. Configure Resource Cleanup

Resource cleanup is automatically configured based on your environment:

**When Cleanup is Enabled (default for persistent networks):**
- Local development (`fullLocal`)
- Testnet (`development`)
- Prevents wasting HBAR and accumulating orphaned resources

**When Cleanup is Disabled (default for ephemeral environments):**
- CI with ephemeral networks (`ciIntegration`)
- No network tests (`quickLocal`, `ciUnit`)
- The network is destroyed anyway, so cleanup is unnecessary overhead

**Override if needed:**

```bash
# Force cleanup on (e.g., long-running testnet tests)
TEST_ENABLE_CLEANUP=1

# Force cleanup off (e.g., CI with ephemeral network)
TEST_ENABLE_CLEANUP=0
```

**Example: CI Configuration**

```yaml
# .github/workflows/test.yml
jobs:
  integration-tests:
    steps:
      - name: Run Integration Tests
        env:
          TEST_PROFILE: ciIntegration
          TEST_ENABLE_CLEANUP: 0  # Ephemeral network, no cleanup needed
          TEST_VERBOSE: 1
        run: swift test --filter HieroIntegrationTests
```

## Summary

**Simplest Setup:**
```bash
# .env
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
```

**With Mirror Node Discovery:**
```bash
# .env
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
TEST_MIRROR_NODES=custom.mirror.com:443
# Automatically uses Client.forMirrorNetwork (no consensus nodes specified)
```

**Most Flexible:**
```swift
let config = TestEnvironmentConfig.builder()
    .type(.testnet)
    .operator(operatorConfig)
    .network(networkConfig)
    .features(featureFlags)
    .build()
```

**Recommended for Teams:**
- Store credentials in CI/CD secrets
- Use different accounts per environment
- Document configuration in README
- Monitor spending on testnet/previewnet
- Never use mainnet for automated tests
- Use mirror node discovery for managed networks

---

For more examples, see:
- `Tests/README.md` - Complete testing guide
- `Tests/HieroTestSupport/Environment/` - Configuration source code
