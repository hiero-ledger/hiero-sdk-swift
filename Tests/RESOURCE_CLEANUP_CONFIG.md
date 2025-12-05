# Resource Cleanup Configuration

## Overview

Resource cleanup is now configurable to optimize test execution in different environments. In CI environments with ephemeral networks, cleanup is unnecessary overhead since the entire network is destroyed after tests complete.

## Cleanup Behavior by Environment

### Cleanup Enabled (Default)
- **Local development** (`fullLocal`)
- **Testnet** (`development`, `fullRegression`)
- **Reason**: Persistent networks require cleanup to avoid wasting HBAR and leaving orphaned resources

### Cleanup Disabled
- **CI environments** (`ciIntegration`, `ciUnit`)
- **Performance testing** (`performance`)
- **Unit tests** (`quickLocal`)
- **Reason**: Ephemeral networks are destroyed automatically, or no network resources are created

## Configuration

### Environment Variable

```bash
# Enable cleanup (default for persistent networks)
TEST_ENABLE_CLEANUP=1

# Disable cleanup (default for ephemeral/CI environments)
TEST_ENABLE_CLEANUP=0
```

### Test Profiles

Each profile has sensible defaults:

| Profile | Cleanup Enabled | Reason |
|---------|----------------|---------|
| `quickLocal` | ❌ No | No network resources created |
| `fullLocal` | ✅ Yes | Local node persists, cleanup important |
| `ciUnit` | ❌ No | No network resources created |
| `ciIntegration` | ❌ No | Ephemeral network destroyed after tests |
| `development` | ✅ Yes | Testnet is persistent, avoid wasting HBAR |
| `fullRegression` | ✅ Yes | Long-running on testnet, cleanup important |
| `performance` | ❌ No | Avoid affecting performance measurements |

### Programmatic Configuration

```swift
// Enable cleanup explicitly
let config = TestEnvironmentConfig.builder()
    .type(.testnet)
    .features(FeatureFlags(enableResourceCleanup: true))
    .build()

// Disable cleanup explicitly
let config = TestEnvironmentConfig.builder()
    .type(.ci)
    .features(FeatureFlags(enableResourceCleanup: false))
    .build()
```

## Implementation Details

### ResourceManager

The `ResourceManager` now accepts an `enableCleanup` parameter:

```swift
let resourceManager = ResourceManager(
    client: client,
    operatorAccountId: operatorId,
    operatorPrivateKey: operatorKey,
    enableCleanup: true  // configurable
)
```

When cleanup is disabled, `cleanup()` returns early:

```swift
public func cleanup() async throws {
    guard enableCleanup else {
        print("Resource cleanup is disabled - skipping")
        return
    }
    
    // ... perform cleanup actions
}
```

### HieroIntegrationTestCase

The base test class automatically configures cleanup based on the environment:

```swift
open override func setUp() async throws {
    // ...
    resourceManager = ResourceManager(
        client: testEnv.client,
        operatorAccountId: operatorConfig.accountId,
        operatorPrivateKey: operatorConfig.privateKey,
        enableCleanup: config.features.enableResourceCleanup  // from config
    )
}

open override func tearDown() async throws {
    // Only cleanup if enabled
    if let manager = resourceManager, config.features.enableResourceCleanup {
        try await manager.cleanup()
    }
    // ...
}
```

## Benefits

### 1. Faster CI Builds
Skipping unnecessary cleanup operations in CI reduces test execution time.

### 2. Cleaner Testnet
When using persistent networks, cleanup ensures you don't accumulate test resources and waste HBAR.

### 3. Accurate Performance Testing
Disabling cleanup in performance tests ensures measurements aren't affected by cleanup overhead.

### 4. Flexibility
You can override the default behavior per environment using `TEST_ENABLE_CLEANUP`.

## Use Cases

### CI with Ephemeral Network

```yaml
# .github/workflows/test.yml
env:
  TEST_PROFILE: ciIntegration
  TEST_ENABLE_CLEANUP: 0  # Ephemeral network, no cleanup needed
```

The network spins up, tests run, network tears down. Cleanup would be wasted work.

### Local Development

```bash
# .env
TEST_OPERATOR_ID=0.0.1234
TEST_OPERATOR_KEY=302e...
TEST_PROFILE=development
TEST_ENABLE_CLEANUP=1  # Clean up to avoid wasting testnet HBAR
```

### Performance Testing

```bash
# .env.performance
TEST_PROFILE=performance
TEST_ENABLE_CLEANUP=0  # Don't affect measurements
```

## Migration

Existing tests continue to work without changes:

- If you don't specify cleanup configuration, sensible defaults are used
- If you were manually creating `ResourceManager`, add the `enableCleanup` parameter (defaults to `true` for backward compatibility)

### Before

```swift
let resourceManager = ResourceManager(
    client: client,
    operatorAccountId: operatorId,
    operatorPrivateKey: operatorKey
)
```

### After

```swift
// Explicitly configure
let resourceManager = ResourceManager(
    client: client,
    operatorAccountId: operatorId,
    operatorPrivateKey: operatorKey,
    enableCleanup: config.features.enableResourceCleanup
)

// Or use default (true)
let resourceManager = ResourceManager(
    client: client,
    operatorAccountId: operatorId,
    operatorPrivateKey: operatorKey
)
```

## Result

✅ Build succeeds
✅ CI tests run faster (no unnecessary cleanup)
✅ Local/testnet development still cleans up properly
✅ Performance tests aren't affected by cleanup overhead
✅ Backward compatible with existing code

