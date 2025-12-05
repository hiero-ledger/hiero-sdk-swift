# Test Profile Consolidation

## Summary

Simplified test profiles from 5 to 4 by consolidating `quickLocal` and `fullLocal` into a single `local` profile.

## Rationale

In practice, developers don't switch between profiles when running unit vs integration tests - they use test filters instead:

```bash
# Run only unit tests
swift test --filter HieroUnitTests

# Run only integration tests  
swift test --filter HieroIntegrationTests

# Run all tests
swift test
```

The profile controls feature flags and environment settings, not which tests run. Having separate `quickLocal` and `fullLocal` profiles just adds unnecessary configuration overhead.

## New Profile Structure

### `local` (for local development)
- **Use case**: All local development work
- **Supports**: Both unit and integration tests
- **Network**: Local Hedera node (127.0.0.1:50211)
- **Default to**: This profile is now the default when no `TEST_PROFILE` is specified
- **Feature flags**:
  - Network required: ✓ (allows running integration tests)
  - Snapshots: ✓ (for unit tests)
  - Max test duration: 300s
  - Parallel execution: ✓
  - Verbose logging: ✗
  - Cleanup policy: economical (only cleanup accounts/contracts that recover HBAR)

### `ciUnit` (for CI unit tests)
- **Use case**: CI pipeline running unit tests only
- **Supports**: Unit tests
- **Network**: None required
- **Feature flags**:
  - Network required: ✗
  - Snapshots: ✓
  - Max test duration: 120s
  - Parallel execution: ✗ (for CI stability)
  - Verbose logging: ✓
  - Cleanup policy: none (ephemeral network)

### `ciIntegration` (for CI integration tests)
- **Use case**: CI pipeline running integration tests
- **Supports**: Integration tests
- **Network**: Local Hedera node (ephemeral)
- **Feature flags**:
  - Network required: ✓
  - Snapshots: ✗ (not needed for integration tests)
  - Max test duration: 600s
  - Parallel execution: ✗ (for CI stability)
  - Verbose logging: ✓
  - Cleanup policy: none (ephemeral network will be destroyed)

### `development` (for remote environments)
- **Use case**: Running integration tests against testnet, previewnet, or custom networks
- **Supports**: Integration tests
- **Network**: Configurable (typically testnet)
- **Feature flags**:
  - Network required: ✓
  - Snapshots: ✗
  - Max test duration: 300s
  - Parallel execution: ✓
  - Verbose logging: ✓
  - Cleanup policy: economical

## Configuration Examples

### Local Development (.env)

```bash
TEST_PROFILE=local  # or omit - local is the default
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e020100300506032b...
```

Run tests:
```bash
# Run all tests (unit + integration)
swift test

# Run only unit tests
swift test --filter HieroUnitTests

# Run only integration tests
swift test --filter HieroIntegrationTests
```

### CI Configuration

**Unit tests job:**
```bash
TEST_PROFILE=ciUnit
# No operator or network needed
```

**Integration tests job:**
```bash
TEST_PROFILE=ciIntegration
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e020100300506032b...
# Ephemeral network configured separately
```

### Development/Testnet (.env)

```bash
TEST_PROFILE=development
TEST_OPERATOR_ID=0.0.12345
TEST_OPERATOR_KEY=302e020100300506032b...
TEST_MIRROR_NODES=testnet.mirrornode.hedera.com:443
# Optionally specify consensus nodes, or let mirror node discovery handle it
```

## Migration Guide

If you were using `quickLocal` or `fullLocal`, switch to `local`:

**Before:**
```bash
TEST_PROFILE=quickLocal  # or fullLocal
```

**After:**
```bash
TEST_PROFILE=local
# or omit it - local is now the default
```

Then use test filters to control which tests run, not the profile.

## Benefits

1. **Simpler mental model**: One profile for local dev, CI profiles for CI, development profile for remote testing
2. **Less configuration churn**: No need to edit `.env` when switching between unit and integration tests
3. **Flexibility**: Use test filters (`--filter`) to control what runs, not profile switching
4. **Sensible defaults**: The `local` profile is now the default, making setup even easier

## Implementation Details

### Changes Made

1. **TestProfile.swift**:
   - Removed `quickLocal` and `fullLocal` cases
   - Added single `local` case
   - Changed default from `development` to `local`

2. **FeatureFlags.swift**:
   - Removed `.quickLocal` and `.fullLocal` static properties
   - Added single `.local` with sensible defaults for both unit and integration tests
   - Uses `economical` cleanup policy (only cleanup resources that recover HBAR)

3. **TestEnvironmentType.swift**:
   - Fixed `defaultNetworkName` to include `.custom` case

4. **IntegrationTestEnvironment.swift**:
   - Updated switch case to use valid `.custom` enum case instead of invalid `.ci` and `.integration`

5. **EnvironmentVariables.swift** & **FeatureFlags.swift**:
   - Updated to properly handle optional Boolean environment variables
   - Proper string-to-boolean conversion ("1" = true, anything else = false)

