# Environment Variable Unification & Cleanup

## Summary

Unified all environment variables under the `TEST_` prefix, added support for multiple consensus nodes, and removed deprecated `TEST_RUN_NONFREE` flag.

**Date:** November 12, 2025

## Problems Addressed

1. **Inconsistent prefixes**: Mix of `LOCAL_*` and `TEST_*` variables
2. **Single node limitation**: Could only specify one consensus node
3. **Deprecated flags**: `TEST_RUN_NONFREE` was still present but no longer needed
4. **Overlap**: `LOCAL_MIRROR_NODE_ADDRESS` vs `TEST_MIRROR_NODES` for same purpose

## What Changed

### 1. Unified Prefix (`TEST_` for all)

**Before:**
```bash
LOCAL_NODE_ADDRESS=127.0.0.1:50211
LOCAL_NODE_ACCOUNT_ID=0.0.3
LOCAL_MIRROR_NODE_ADDRESS=127.0.0.1:5600
TEST_MIRROR_NODES=mirror1.com:443,mirror2.com:443  # Only for non-local
```

**After:**
```bash
TEST_CONSENSUS_NODES=127.0.0.1:50211
TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3
TEST_MIRROR_NODES=127.0.0.1:5600  # Works for ALL environments
```

### 2. Multiple Consensus Nodes Support

**Before (single node only):**
```bash
LOCAL_NODE_ADDRESS=127.0.0.1:50211
LOCAL_NODE_ACCOUNT_ID=0.0.3
```

**After (multiple nodes):**
```bash
TEST_CONSENSUS_NODES=127.0.0.1:50211,192.168.1.100:50211,192.168.1.101:50211
TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4,0.0.5
```

The counts must match, or a warning is printed.

### 3. Removed `TEST_RUN_NONFREE`

This flag was originally used to gate "expensive" tests, but we've since clarified:
- Tests either use HBAR (integration tests) or don't (unit tests)
- Integration tests require an operator, so we check for operator presence directly

**Before:**
```swift
if type.requiresOperator && operatorConfig == nil && EnvironmentVariables.runNonfreeTests {
    throw TestEnvironmentError.missingOperatorCredentials
}
```

**After:**
```swift
if type.requiresOperator && operatorConfig == nil {
    throw TestEnvironmentError.missingOperatorCredentials
}
```

### 4. Unified Mirror Node Configuration

**Before:**
- `LOCAL_MIRROR_NODE_ADDRESS` for local networks
- `TEST_MIRROR_NODES` for other networks

**After:**
- `TEST_MIRROR_NODES` for ALL networks (comma-separated)
- Defaults to `127.0.0.1:5600` for `.local` profile if not specified

## Code Changes

### `Tests/HieroTestSupport/Environment/EnvironmentVariables.swift`

**Removed:**
```swift
public static var localNodeAddress: String? { env["LOCAL_NODE_ADDRESS"] }
public static var localNodeAccountId: String? { env["LOCAL_NODE_ACCOUNT_ID"] }
public static var localMirrorNodeAddress: String? { env["LOCAL_MIRROR_NODE_ADDRESS"] }
public static var runNonfreeTests: Bool { env["TEST_RUN_NONFREE"] == "1" }
```

**Added:**
```swift
/// Comma-separated consensus node addresses
public static var consensusNodes: [String] {
    guard let nodesStr = env["TEST_CONSENSUS_NODES"] else { return [] }
    return nodesStr.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
}

/// Comma-separated consensus node account IDs (must match count)
public static var consensusNodeAccountIds: [String] {
    guard let idsStr = env["TEST_CONSENSUS_NODE_ACCOUNT_IDS"] else { return [] }
    return idsStr.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
}
```

### `Tests/HieroTestSupport/Environment/NetworkConfig.swift`

**Before (single node, LOCAL_ vars):**
```swift
case .local:
    let nodeAddress = EnvironmentVariables.localNodeAddress ?? "127.0.0.1:50211"
    let nodeAccountStr = EnvironmentVariables.localNodeAccountId ?? "0.0.3"
    let nodeAccount = try? AccountId.fromString(nodeAccountStr)
    let mirrorAddress = EnvironmentVariables.localMirrorNodeAddress ?? "127.0.0.1:5600"
    
    return NetworkConfig(
        nodes: [nodeAddress: nodeAccount ?? AccountId(num: 3)],
        mirrorNodes: [mirrorAddress]
    )
```

**After (multiple nodes, TEST_ vars):**
```swift
// Read consensus nodes from environment
let consensusNodes = EnvironmentVariables.consensusNodes
let consensusAccountIds = EnvironmentVariables.consensusNodeAccountIds
let mirrorNodes = EnvironmentVariables.mirrorNodes

// Build consensus node map if specified
var nodes: [String: AccountId] = [:]
if !consensusNodes.isEmpty {
    guard consensusNodes.count == consensusAccountIds.count else {
        print("WARNING: TEST_CONSENSUS_NODES count doesn't match TEST_CONSENSUS_NODE_ACCOUNT_IDS count")
        return NetworkConfig(nodes: [:], mirrorNodes: mirrorNodes)
    }
    
    for (address, accountIdStr) in zip(consensusNodes, consensusAccountIds) {
        if let accountId = try? AccountId.fromString(accountIdStr) {
            nodes[address] = accountId
        }
    }
} else if type == .local {
    // Local defaults
    nodes = ["127.0.0.1:50211": AccountId(num: 3)]
}

// Mirror nodes: use env var if specified, otherwise local default for .local type
let finalMirrorNodes: [String]
if !mirrorNodes.isEmpty {
    finalMirrorNodes = mirrorNodes
} else if type == .local {
    finalMirrorNodes = ["127.0.0.1:5600"]
} else {
    finalMirrorNodes = []
}
```

### `Tests/HieroTestSupport/Environment/TestEnvironmentConfig.swift`

**Removed:**
```swift
if type.requiresOperator && operatorConfig == nil && EnvironmentVariables.runNonfreeTests {
    throw TestEnvironmentError.missingOperatorCredentials
}
```

**Simplified to:**
```swift
if type.requiresOperator && operatorConfig == nil {
    throw TestEnvironmentError.missingOperatorCredentials
}
```

### `Tests/HieroE2ETests/Config.swift` (Legacy)

Removed all `TEST_RUN_NONFREE` references:
- Removed `Keys.runNonfree`
- Removed `runNonfreeTests` property
- Changed `NonfreeTestEnvironment.Config` to check for operator presence instead

## Usage Examples

### Example 1: Local Network (Single Node)

```bash
# .env
TEST_PROFILE=fullLocal
# Uses defaults: 127.0.0.1:50211 (account 0.0.3), mirror 127.0.0.1:5600
```

### Example 2: Local Network (Multiple Nodes)

```bash
# .env
TEST_PROFILE=fullLocal
TEST_CONSENSUS_NODES=127.0.0.1:50211,127.0.0.1:50212,127.0.0.1:50213
TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4,0.0.5
TEST_MIRROR_NODES=127.0.0.1:5600
```

### Example 3: Custom Network with Mirror Discovery

```bash
# .env
TEST_PROFILE=development
TEST_MIRROR_NODES=mainnet.mirrornode.hedera.com:443,backup.mirror.com:443
# No consensus nodes = uses Client.forMirrorNetwork() automatically
```

### Example 4: Testnet (Defaults)

```bash
# .env
TEST_PROFILE=development
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
# No nodes specified = uses Client.forTestnet() with defaults
```

## Environment Variables Reference

### Consensus & Mirror Nodes

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `TEST_CONSENSUS_NODES` | [String] | `.local`: `127.0.0.1:50211` | Comma-separated addresses |
| `TEST_CONSENSUS_NODE_ACCOUNT_IDS` | [String] | `.local`: `0.0.3` | Comma-separated account IDs (must match node count) |
| `TEST_MIRROR_NODES` | [String] | `.local`: `127.0.0.1:5600` | Comma-separated mirror addresses |

### Removed Variables

| Variable | Reason |
|----------|--------|
| `LOCAL_NODE_ADDRESS` | Replaced by `TEST_CONSENSUS_NODES` |
| `LOCAL_NODE_ACCOUNT_ID` | Replaced by `TEST_CONSENSUS_NODE_ACCOUNT_IDS` |
| `LOCAL_MIRROR_NODE_ADDRESS` | Unified into `TEST_MIRROR_NODES` |
| `TEST_RUN_NONFREE` | Deprecated - check operator presence instead |

## Migration Guide

### If you were using LOCAL_* variables:

**Old `.env`:**
```bash
LOCAL_NODE_ADDRESS=192.168.1.100:50211
LOCAL_NODE_ACCOUNT_ID=0.0.5
LOCAL_MIRROR_NODE_ADDRESS=192.168.1.100:5600
```

**New `.env`:**
```bash
TEST_CONSENSUS_NODES=192.168.1.100:50211
TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.5
TEST_MIRROR_NODES=192.168.1.100:5600
```

### If you were using TEST_RUN_NONFREE:

**Old `.env`:**
```bash
TEST_RUN_NONFREE=1
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
```

**New `.env` (just remove the flag):**
```bash
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
```

Integration tests will run if operator credentials are present.

### If you want multiple consensus nodes:

**New capability:**
```bash
TEST_CONSENSUS_NODES=node1.example.com:50211,node2.example.com:50211,node3.example.com:50211
TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4,0.0.5
```

## Benefits

✅ **Consistent naming** - All test variables use `TEST_` prefix  
✅ **Scalability** - Support for multiple consensus nodes  
✅ **Simplicity** - Removed unnecessary `TEST_RUN_NONFREE` flag  
✅ **Unification** - One mirror node variable for all environments  
✅ **Backwards compatible** - Sensible defaults for `.local` profile  

## Documentation Updates

All documentation has been updated:
- ✅ `Tests/ENVIRONMENT_VARIABLES.md`
- ✅ `Tests/README.md`
- ✅ `Tests/CONFIGURATION_GUIDE.md`

## Build Status

✅ All builds passing after changes

