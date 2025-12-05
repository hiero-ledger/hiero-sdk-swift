# Test Profile Simplification & Mirror Node Support

## Overview

Simplified the test profiles from 7 to 5, removing unnecessary complexity while adding support for `Client.forMirrorNetwork` for environments that discover consensus nodes via mirror node address books.

## Changes

### 1. Simplified Test Profiles

**Removed:**
- `fullRegression` - Redundant with `development` profile
- `performance` - Can be achieved with feature flags on `development` profile

**Kept (5 profiles):**
- `quickLocal` - Unit tests on local machine
- `fullLocal` - Unit and integration tests on local machine
- `ciUnit` - Unit tests in CI
- `ciIntegration` - Integration tests in CI with ephemeral network
- `development` - Integration tests in another environment

### 2. Added Mirror Node Address Book Support

Added ability to use `Client.forMirrorNetwork()` for environments where consensus nodes are discovered dynamically via mirror node.

**New Configuration Fields:**

```swift
// NetworkConfig.swift
public struct NetworkConfig {
    // ... existing fields ...
    public let useMirrorNodeAddressBook: Bool  // NEW
}
```

**New Environment Variables:**
```bash
TEST_MIRROR_NODES=mainnet.mirrornode.hedera.com:443,backup.mirror.com:443
# Automatically uses Client.forMirrorNetwork when no consensus nodes are configured
```

## Test Profiles

### Before (7 profiles)

```swift
public enum TestProfile {
    case quickLocal
    case fullLocal
    case ciUnit
    case ciIntegration
    case development
    case fullRegression  // ❌ Removed
    case performance     // ❌ Removed
}
```

### After (5 profiles)

```swift
public enum TestProfile {
    case quickLocal      // Unit tests on local machine
    case fullLocal       // Unit + integration on local machine
    case ciUnit          // Unit tests in CI
    case ciIntegration   // Integration tests in CI
    case development     // Integration tests in another environment
}
```

## Mirror Network Configuration

### When to Use

Use mirror node address book when:
- Working with custom/managed Hedera networks
- Consensus nodes are dynamically configured
- You only have access to mirror nodes
- The network requires address book discovery

### Configuration Example

**Environment Variables:**

```bash
# .env
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
TEST_PROFILE=development
TEST_MIRROR_NODES=custom.mirror.com:443,backup.mirror.com:443
# No consensus nodes = automatically uses Client.forMirrorNetwork
```

**Programmatic:**

```swift
let networkConfig = NetworkConfig(
    nodes: [:],  // Will be discovered via mirror node
    mirrorNodes: ["custom.mirror.com:443"],
    useMirrorNodeAddressBook: true
)

let config = TestEnvironmentConfig(
    type: .testnet,
    network: networkConfig,
    operator: operatorConfig,
    features: featureFlags,
    profile: .development
)

let testEnv = try await IntegrationTestEnvironment.create(config: config)
```

### How It Works

When `useMirrorNodeAddressBook` is enabled:

1. **Client Creation:**
   ```swift
   let client = try await Client.forMirrorNetwork(mirrorNodes)
   ```

2. **Address Book Query:**
   - Client queries the mirror node(s) for the network's address book
   - Discovers available consensus nodes dynamically
   - Configures itself with the discovered nodes

3. **Operator Setup:**
   - Sets operator credentials as normal
   - Ready to submit transactions

### Standard vs Mirror Network Mode

**Standard Mode (default):**
```swift
// Uses predefined network
let client = Client.forTestnet()
// or
let client = try Client.forNetwork(consensusNodes)
```

**Mirror Network Mode:**
```swift
// Discovers network via mirror node
let client = try await Client.forMirrorNetwork(mirrorNodes)
```

## Profile Comparison

| Profile | Network | Cleanup | Features | Use Case |
|---------|---------|---------|----------|----------|
| **quickLocal** | None | No | Minimal | Fast unit tests |
| **fullLocal** | Local node | Yes | Full | Complete local testing |
| **ciUnit** | None | No | Snapshots | CI unit tests |
| **ciIntegration** | CI/Ephemeral | No | Verbose | CI integration tests |
| **development** | Testnet/Custom | Yes | Balanced | Developer workstation |

## Rationale for Removal

### Why Remove `fullRegression`?

The `fullRegression` profile was essentially the same as `development` but with:
- Longer timeouts (1200s vs 300s)
- All features enabled

These can be achieved with the `development` profile + environment variables:

```bash
# Instead of TEST_PROFILE=fullRegression
TEST_PROFILE=development
TEST_MAX_DURATION=1200
TEST_SKIP_SLOW=0
```

### Why Remove `performance`?

The `performance` profile's main distinguishing features were:
- Cleanup disabled (to not affect measurements)
- Snapshots disabled
- Longer timeouts
- Verbose logging

These are all configurable via environment variables:

```bash
# Instead of TEST_PROFILE=performance
TEST_PROFILE=development
TEST_ENABLE_CLEANUP=0
TEST_ENABLE_SNAPSHOTS=0
TEST_MAX_DURATION=1800
TEST_VERBOSE=1
```

## Migration Guide

### From `fullRegression`

**Before:**
```bash
TEST_PROFILE=fullRegression
```

**After:**
```bash
TEST_PROFILE=development
TEST_MAX_DURATION=1200
TEST_SKIP_SLOW=0
```

### From `performance`

**Before:**
```bash
TEST_PROFILE=performance
```

**After:**
```bash
TEST_PROFILE=development
TEST_ENABLE_CLEANUP=0
TEST_ENABLE_SNAPSHOTS=0
TEST_MAX_DURATION=1800
TEST_VERBOSE=1
```

## Example Use Cases

### 1. Local Development (Quick Iteration)

```bash
TEST_PROFILE=quickLocal
```

### 2. Local Development (Full Testing)

```bash
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e...
TEST_PROFILE=fullLocal
```

### 3. Testnet Development

```bash
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=your_key
TEST_PROFILE=development
```

### 4. Custom Network via Mirror Node

```bash
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=your_key
TEST_PROFILE=development
TEST_MIRROR_NODES=custom.mirror.com:443
# Mirror nodes without consensus nodes = automatic address book query
```

### 5. CI Unit Tests

```yaml
env:
  TEST_PROFILE: ciUnit
```

### 6. CI Integration Tests

```yaml
env:
  TEST_PROFILE: ciIntegration
  TEST_OPERATOR_ID: ${{ secrets.OPERATOR_ID }}
  TEST_OPERATOR_KEY: ${{ secrets.OPERATOR_KEY }}
  TEST_ENABLE_CLEANUP: 0  # Ephemeral network
```

## Files Modified

### Code Changes

1. **`Tests/HieroTestSupport/Environment/TestProfile.swift`**
   - Removed `fullRegression` and `performance` enum cases
   - Updated `environmentType` switch statement
   - Updated `featureFlags` switch statement

2. **`Tests/HieroTestSupport/Environment/NetworkConfig.swift`**
   - Added computed property `useMirrorNodeAddressBook: Bool` that automatically returns `true` when mirror nodes are specified but consensus nodes are empty
   - Added support for `TEST_MIRROR_NODES` environment variable (comma-separated)

3. **`Tests/HieroTestSupport/Base/HieroIntegrationTestCase.swift`**
   - Updated `IntegrationTestEnvironment.create()` to check `useMirrorNodeAddressBook`
   - Added conditional logic to use `Client.forMirrorNetwork()` when `useMirrorNodeAddressBook` is `true` (automatically inferred)

### Documentation Updates

4. **`Tests/README.md`**
   - Updated test profiles list (7 → 5)
   - Added mirror node configuration section
   - Updated profile table

5. **`Tests/CONFIGURATION_GUIDE.md`**
   - Completely rewritten with mirror node documentation
   - Updated all profile references
   - Added mirror network examples

6. **`Tests/MIGRATION_SUMMARY.md`**
   - Updated profile count (7 → 5)
   - Added mirror node support note

## Benefits

### Simplicity
- Fewer profiles to understand and maintain
- Clearer mental model: profiles for scenarios, env vars for tweaks

### Flexibility
- Can achieve any configuration via env vars
- No need to add new profiles for variations

### Power
- Mirror node support enables custom/managed networks
- Dynamic node discovery for changing environments

### Consistency
- `development` profile works for any non-CI integration testing
- Feature flags provide fine-grained control

## Testing

```bash
# Build test support module
swift build --target HieroTestSupport

# Status: ✅ Success
```

## Result

✅ Simplified from 7 to 5 profiles  
✅ Added mirror node address book support  
✅ More flexible configuration via environment variables  
✅ Clearer separation between profiles and feature flags  
✅ Supports custom/managed Hedera networks  
✅ All builds pass  
✅ Documentation updated

