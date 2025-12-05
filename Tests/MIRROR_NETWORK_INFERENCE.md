# Mirror Network Inference - Automatic Configuration

## Summary

Removed the explicit `TEST_USE_MIRROR_ADDRESS_BOOK` environment variable and made mirror network usage automatic based on configuration inference.

**Date:** November 11, 2025

## Problem

The `TEST_USE_MIRROR_ADDRESS_BOOK` environment variable was exposing implementation details. Users had to explicitly opt-in to using `Client.forMirrorNetwork()`, which created unnecessary configuration complexity.

## Solution

**Smart Inference:** The framework now automatically determines whether to use `Client.forMirrorNetwork()` based on what's configured:

```swift
public var useMirrorNodeAddressBook: Bool {
    // Use mirror network address book if:
    // 1. Mirror nodes are specified, AND
    // 2. No consensus nodes are specified (empty nodes dict)
    return !mirrorNodes.isEmpty && nodes.isEmpty
}
```

## What Changed

### Code Changes

1. **`Tests/HieroTestSupport/Environment/EnvironmentVariables.swift`**
   - ❌ Removed `useMirrorAddressBook: Bool` property

2. **`Tests/HieroTestSupport/Environment/NetworkConfig.swift`**
   - Changed `useMirrorNodeAddressBook` from stored property to computed property
   - Logic automatically infers based on whether consensus nodes are empty
   - Removed `useMirrorNodeAddressBook` parameter from initializer

### Documentation Changes

Updated all documentation files to remove `TEST_USE_MIRROR_ADDRESS_BOOK`:
- `Tests/README.md`
- `Tests/CONFIGURATION_GUIDE.md`
- `Tests/PROFILE_SIMPLIFICATION.md`
- `Tests/ENVIRONMENT_VARIABLES.md`

## Usage Examples

### Before (explicit flag - ❌ bad)

```bash
# Had to explicitly enable mirror network
TEST_MIRROR_NODES=mainnet.mirrornode.hedera.com:443
TEST_USE_MIRROR_ADDRESS_BOOK=1  # ❌ Implementation detail exposed
```

### After (automatic - ✅ good)

```bash
# Just specify mirror nodes, framework figures it out
TEST_MIRROR_NODES=mainnet.mirrornode.hedera.com:443
# No consensus nodes = automatically uses Client.forMirrorNetwork()
```

## Configuration Scenarios

### Scenario 1: Mirror Network Discovery (Development)

```bash
# .env
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
TEST_PROFILE=development
TEST_MIRROR_NODES=custom.mirror.com:443
# Result: Uses Client.forMirrorNetwork() automatically
```

### Scenario 2: Explicit Consensus Nodes (Local)

```bash
# .env
TEST_PROFILE=fullLocal
LOCAL_NODE_ADDRESS=192.168.1.100:50211
LOCAL_NODE_ACCOUNT_ID=0.0.3
# Result: Uses explicit consensus nodes
```

### Scenario 3: Default Network (Testnet)

```bash
# .env
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
TEST_PROFILE=development
# No mirror nodes, no explicit consensus nodes
# Result: Uses default testnet nodes from Client.forTestnet()
```

## Benefits

✅ **Simpler Configuration** - One less environment variable to set  
✅ **Intent-Based** - Configuration reflects what you want, not how to do it  
✅ **No Implementation Leakage** - Users don't need to know about `Client.forMirrorNetwork()`  
✅ **Backwards Compatible** - Existing configs without the flag still work  
✅ **Self-Documenting** - Presence/absence of nodes implies behavior  

## Migration

**No action required!** This change is fully backwards compatible:

- Old configs with `TEST_USE_MIRROR_ADDRESS_BOOK=1` → Still works (flag is ignored)
- New configs without the flag → Works automatically based on inference

## Technical Details

### Inference Logic

```swift
// In NetworkConfig.swift
public var useMirrorNodeAddressBook: Bool {
    return !mirrorNodes.isEmpty && nodes.isEmpty
}

// Truth table:
// mirrorNodes | nodes | useMirrorNodeAddressBook
// ------------|-------|-------------------------
// []          | []    | false (use defaults)
// []          | [...]  | false (use explicit nodes)
// [...]       | []    | true (discover via mirror)
// [...]       | [...]  | false (use explicit nodes)
```

### Client Creation

```swift
// In HieroIntegrationTestCase.swift
if config.network.useMirrorNodeAddressBook {
    // Automatically detected!
    client = try await Client.forMirrorNetwork(config.network.mirrorNodes)
} else {
    // Standard client creation
    switch config.type {
    case .local: client = Client(nodes: config.network.nodes)
    case .testnet: client = Client.forTestnet()
    // ...
    }
}
```

## Philosophy

**Configuration should express intent, not implementation.**

- ❌ Bad: "Use the mirror network address book feature"
- ✅ Good: "Here are my mirror nodes (and framework figures out the rest)"

This change embodies this philosophy by making the framework smarter about user intent.

