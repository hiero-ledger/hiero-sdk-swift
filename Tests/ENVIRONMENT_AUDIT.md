# Environment Variables Audit & Defaults

Complete documentation of all environment variables, their defaults, requirements, and validation rules.

## Table of Contents
- [Configuration Structs & Defaults](#configuration-structs--defaults)
- [Environment Variables by Category](#environment-variables-by-category)
- [Requirements by Profile](#requirements-by-profile)
- [Validation Rules](#validation-rules)
- [Examples](#examples)

---

## Configuration Structs & Defaults

### `FeatureFlags`

Controls test execution behavior and features.

```swift
public struct FeatureFlags {
    public var networkRequired: Bool         // Default: true
    public var enableSnapshots: Bool         // Default: true
    public var maxTestDuration: TimeInterval // Default: 300 seconds (5 minutes)
    public var parallelExecution: Bool       // Default: true
    public var verboseLogging: Bool          // Default: false
    public var cleanupPolicy: CleanupPolicy  // Default: .economical
}
```

**Profile-Specific Defaults:**

| Profile | networkRequired | enableSnapshots | maxTestDuration | parallelExecution | verboseLogging | cleanupPolicy |
|---------|----------------|-----------------|-----------------|-------------------|----------------|---------------|
| `local` | ✓ true | ✓ true | 300s | ✓ true | ✗ false | economical |
| `ciUnit` | ✗ false | ✓ true | 120s | ✗ false | ✓ true | none |
| `ciIntegration` | ✓ true | ✗ false | 600s | ✗ false | ✓ true | none |
| `development` | ✓ true | ✗ false | 300s | ✓ true | ✓ true | economical |

### `CleanupPolicy`

Controls which test resources are cleaned up after tests complete.

```swift
public struct CleanupPolicy {
    public var cleanupAccounts: Bool   // Default: true (recovers HBAR)
    public var cleanupTokens: Bool     // Default: false (costs HBAR)
    public var cleanupFiles: Bool      // Default: false (costs HBAR)
    public var cleanupTopics: Bool     // Default: false (costs HBAR)
    public var cleanupContracts: Bool  // Default: true (can recover HBAR)
}
```

**Predefined Policies:**

| Policy | accounts | tokens | files | topics | contracts | Use Case |
|--------|----------|--------|-------|--------|-----------|----------|
| `.none` | ✗ | ✗ | ✗ | ✗ | ✗ | CI ephemeral networks |
| `.economical` | ✓ | ✗ | ✗ | ✗ | ✓ | Default - only cleanup HBAR-recovering resources |
| `.all` | ✓ | ✓ | ✓ | ✓ | ✓ | Complete cleanup |

### `NetworkConfig`

Defines network connectivity for tests.

```swift
public struct NetworkConfig {
    public let nodes: [String: AccountId]  // Consensus node addresses -> account IDs
    public let mirrorNodes: [String]       // Mirror node addresses
    public let networkUpdatePeriod: UInt64? // Network update period (nanoseconds)
}
```

**Defaults by Environment Type:**

| Environment Type | Default Consensus Nodes | Default Mirror Nodes |
|------------------|------------------------|---------------------|
| `.unit` | None (no network) | None |
| `.local` | `127.0.0.1:50211` → `0.0.3` | `127.0.0.1:5600` |
| `.testnet` | Uses `Client.forTestnet()` | N/A |
| `.previewnet` | Uses `Client.forPreviewnet()` | N/A |
| `.mainnet` | Uses `Client.forMainnet()` | N/A |
| `.custom` | Must be configured | Must be configured |

### `OperatorConfig`

Operator account credentials for transaction signing.

```swift
public struct OperatorConfig {
    public let accountId: AccountId
    public let privateKey: PrivateKey
}
```

**Required for:** All environment types except `.unit`

**No defaults** - must be provided via environment variables when required.

---

## Environment Variables by Category

### Operator Configuration

#### `TEST_OPERATOR_ID`
- **Type:** String
- **Required:** ⚠️ Conditional - For integration tests (all profiles except `ciUnit`)
- **Default:** None
- **Validation:** Must be valid AccountId format (e.g., `0.0.1234`)
- **Example:** `TEST_OPERATOR_ID=0.0.1234`

#### `TEST_OPERATOR_KEY`
- **Type:** String
- **Required:** ⚠️ Conditional - For integration tests (all profiles except `ciUnit`)
- **Default:** None
- **Validation:** 
  - Must be at least 64 characters (hex-encoded private key)
  - Trimmed of whitespace/newlines automatically
- **Example:** `TEST_OPERATOR_KEY=302e020100300506032b657004220420...`

### Network Configuration

#### `TEST_PROFILE`
- **Type:** Enum: `local` | `ciUnit` | `ciIntegration` | `development`
- **Required:** ✗ Optional
- **Default:** `local`
- **Description:** Test profile determines environment type and feature flag defaults
- **Example:** `TEST_PROFILE=local`

#### `TEST_ENVIRONMENT_TYPE`
- **Type:** Enum: `unit` | `local` | `testnet` | `previewnet` | `mainnet` | `custom`
- **Required:** ✗ Optional
- **Default:** Determined by `TEST_PROFILE`
- **Description:** Explicitly override environment type (usually not needed)
- **Example:** `TEST_ENVIRONMENT_TYPE=testnet`

#### `TEST_CONSENSUS_NODES`
- **Type:** String[] (comma-separated)
- **Required:** ⚠️ Conditional - For local or custom network
- **Default:** `127.0.0.1:50211` (for `local` profile only)
- **Validation:** 
  - If set, `TEST_CONSENSUS_NODE_ACCOUNT_IDS` should also be set
  - Count should match `TEST_CONSENSUS_NODE_ACCOUNT_IDS` count
  - Warning (not error) if counts mismatch - uses first N nodes
- **Example:** `TEST_CONSENSUS_NODES=127.0.0.1:50211,192.168.1.100:50211`

#### `TEST_CONSENSUS_NODE_ACCOUNT_IDS`
- **Type:** String[] (comma-separated AccountIds)
- **Required:** ⚠️ Conditional - When `TEST_CONSENSUS_NODES` is set
- **Default:** `0.0.3` (for `local` profile only)
- **Validation:** 
  - Each ID must be valid AccountId format
  - Count should match `TEST_CONSENSUS_NODES` count
- **Example:** `TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4,0.0.5`

#### `TEST_MIRROR_NODES`
- **Type:** String[] (comma-separated)
- **Required:** ⚠️ Conditional - For `development` profile or mirror address book discovery
- **Default:** 
  - `127.0.0.1:5600` (for `local` profile)
  - Empty otherwise
- **Description:** 
  - If set without `TEST_CONSENSUS_NODES`, uses `Client.forMirrorNetwork()` for address book discovery
  - If set with `TEST_CONSENSUS_NODES`, used as mirror network for existing client
- **Example:** `TEST_MIRROR_NODES=testnet.mirrornode.hedera.com:443`

### Feature Flags

All feature flags are **optional** and override profile defaults.

#### `TEST_NETWORK_REQUIRED`
- **Type:** Boolean (`0` or `1`)
- **Default:** Profile-dependent (see table above)
- **Example:** `TEST_NETWORK_REQUIRED=1`

#### `TEST_ENABLE_SNAPSHOTS`
- **Type:** Boolean (`0` or `1`)
- **Default:** Profile-dependent (see table above)
- **Example:** `TEST_ENABLE_SNAPSHOTS=1`

#### `TEST_MAX_DURATION`
- **Type:** Number (seconds)
- **Default:** Profile-dependent (see table above)
- **Example:** `TEST_MAX_DURATION=600`

#### `TEST_PARALLEL`
- **Type:** Boolean (`0` or `1`)
- **Default:** Profile-dependent (see table above)
- **Example:** `TEST_PARALLEL=1`

#### `TEST_VERBOSE`
- **Type:** Boolean (`0` or `1`)
- **Default:** `false`
- **Example:** `TEST_VERBOSE=1`

### Cleanup Policy

All cleanup flags are **optional** and default to **economical** policy.

#### `TEST_ENABLE_CLEANUP`
- **Type:** Boolean (`0` or `1`)
- **Default:** None (deprecated)
- **Description:** Legacy flag - superseded by individual `TEST_CLEANUP_*` flags
  - `1` = enable all cleanup (`.all` policy)
  - `0` = disable all cleanup (`.none` policy)
- **Example:** `TEST_ENABLE_CLEANUP=1`

#### `TEST_CLEANUP_ACCOUNTS`
- **Type:** Boolean (`0` or `1`)
- **Default:** `true`
- **Description:** Cleanup test accounts (recovers HBAR)
- **Example:** `TEST_CLEANUP_ACCOUNTS=1`

#### `TEST_CLEANUP_TOKENS`
- **Type:** Boolean (`0` or `1`)
- **Default:** `false`
- **Description:** Cleanup test tokens (costs HBAR)
- **Example:** `TEST_CLEANUP_TOKENS=1`

#### `TEST_CLEANUP_FILES`
- **Type:** Boolean (`0` or `1`)
- **Default:** `false`
- **Description:** Cleanup test files (costs HBAR)
- **Example:** `TEST_CLEANUP_FILES=1`

#### `TEST_CLEANUP_TOPICS`
- **Type:** Boolean (`0` or `1`)
- **Default:** `false`
- **Description:** Cleanup test topics (costs HBAR)
- **Example:** `TEST_CLEANUP_TOPICS=1`

#### `TEST_CLEANUP_CONTRACTS`
- **Type:** Boolean (`0` or `1`)
- **Default:** `true`
- **Description:** Cleanup test contracts (can recover HBAR)
- **Example:** `TEST_CLEANUP_CONTRACTS=1`

---

## Requirements by Profile

### `local` Profile

**Purpose:** Local development (unit + integration tests)

**Required:**
- ✓ `TEST_OPERATOR_ID`
- ✓ `TEST_OPERATOR_KEY`

**Optional:**
- `TEST_CONSENSUS_NODES` (defaults to `127.0.0.1:50211`)
- `TEST_CONSENSUS_NODE_ACCOUNT_IDS` (defaults to `0.0.3`)
- `TEST_MIRROR_NODES` (defaults to `127.0.0.1:5600`)
- All feature flags and cleanup flags

**Minimal `.env` example:**
```bash
TEST_PROFILE=local  # or omit - local is default
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e020100300506032b657004220420...
```

### `ciUnit` Profile

**Purpose:** CI unit tests (no network)

**Required:** None

**Optional:** All feature flags

**Minimal `.env` example:**
```bash
TEST_PROFILE=ciUnit
```

### `ciIntegration` Profile

**Purpose:** CI integration tests (ephemeral local network)

**Required:**
- ✓ `TEST_OPERATOR_ID`
- ✓ `TEST_OPERATOR_KEY`
- ✓ Network configuration (typically set by CI, not `.env`)

**Optional:** All feature flags and cleanup flags

**Minimal `.env` example:**
```bash
TEST_PROFILE=ciIntegration
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e020100300506032b657004220420...
TEST_CONSENSUS_NODES=127.0.0.1:50211
TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3
TEST_MIRROR_NODES=127.0.0.1:5600
```

### `development` Profile

**Purpose:** Integration tests against remote networks (testnet, previewnet, custom)

**Required:**
- ✓ `TEST_OPERATOR_ID`
- ✓ `TEST_OPERATOR_KEY`
- ✓ **Either** `TEST_MIRROR_NODES` **or** `TEST_CONSENSUS_NODES` (at least one)

**Optional:**
- `TEST_ENVIRONMENT_TYPE` (to override default testnet)
- All feature flags and cleanup flags

**Minimal `.env` examples:**

**Option 1: Using mirror node address book discovery (recommended for testnet/previewnet):**
```bash
TEST_PROFILE=development
TEST_OPERATOR_ID=0.0.12345
TEST_OPERATOR_KEY=302e020100300506032b657004220420...
TEST_MIRROR_NODES=testnet.mirrornode.hedera.com:443
```

**Option 2: Using explicit consensus nodes:**
```bash
TEST_PROFILE=development
TEST_OPERATOR_ID=0.0.12345
TEST_OPERATOR_KEY=302e020100300506032b657004220420...
TEST_CONSENSUS_NODES=0.testnet.hedera.com:50211,1.testnet.hedera.com:50211
TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4
```

---

## Validation Rules

### 1. Operator Credentials Validation

**Trigger:** Any profile except `ciUnit`

**Rules:**
- `TEST_OPERATOR_ID` must be set
- `TEST_OPERATOR_KEY` must be set
- `TEST_OPERATOR_KEY` must be at least 64 characters
- Both are trimmed of whitespace/newlines automatically

**Error Example:**
```
❌ Missing required environment variable: TEST_OPERATOR_ID

Reason: Profile 'local' requires operator credentials

Example: TEST_OPERATOR_ID=0.0.1234

Set this in your .env file or environment.
```

### 2. Network Configuration Validation

**For `local` profile:**
- If `TEST_CONSENSUS_NODES` is set, `TEST_CONSENSUS_NODE_ACCOUNT_IDS` must also be set
- If neither is set, defaults are used

**For `development` profile:**
- At least one of `TEST_MIRROR_NODES` or `TEST_CONSENSUS_NODES` must be set

**Error Example:**
```
❌ Missing required environment variable: TEST_MIRROR_NODES or TEST_CONSENSUS_NODES

Reason: Development profile requires network configuration. Either specify mirror nodes 
for address book discovery, or consensus nodes for direct connection

Example: TEST_MIRROR_NODES=testnet.mirrornode.hedera.com:443

Set this in your .env file or environment.
```

### 3. Consensus Nodes and Account IDs Validation

**Rule:** Count mismatch is a warning, not an error

**Behavior:**
- If counts don't match, uses `min(nodes.count, accountIds.count)` nodes
- Prints warning with details

**Warning Example:**
```
⚠️  WARNING: TEST_CONSENSUS_NODES has 3 node(s), but TEST_CONSENSUS_NODE_ACCOUNT_IDS 
has 2 ID(s). Will use the first 2.
```

### 4. Environment Variable Trimming

**Automatic Trimming Applied To:**
- `TEST_OPERATOR_ID` - whitespace and newlines
- `TEST_OPERATOR_KEY` - whitespace and newlines
- `TEST_CONSENSUS_NODES` - each node address trimmed
- `TEST_CONSENSUS_NODE_ACCOUNT_IDS` - each account ID trimmed
- `TEST_MIRROR_NODES` - each mirror node address trimmed

**Rationale:** Prevent subtle bugs from trailing whitespace in `.env` files

---

## Examples

### Example 1: Minimal Local Development

```bash
# .env
TEST_PROFILE=local
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e020100300506032b657004220420...
```

**Result:**
- Uses local Hedera node at `127.0.0.1:50211` (default)
- Uses local mirror node at `127.0.0.1:5600` (default)
- Economical cleanup (accounts + contracts)
- Snapshots enabled
- Parallel execution enabled

### Example 2: Local Development with Custom Network

```bash
# .env
TEST_PROFILE=local
TEST_OPERATOR_ID=0.0.1001
TEST_OPERATOR_KEY=302e020100300506032b657004220420...
TEST_CONSENSUS_NODES=192.168.1.100:50211,192.168.1.101:50211
TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4
TEST_MIRROR_NODES=192.168.1.100:5600
```

**Result:**
- Uses custom consensus nodes
- Uses custom mirror node
- All other defaults from `local` profile

### Example 3: Development Against Testnet

```bash
# .env
TEST_PROFILE=development
TEST_OPERATOR_ID=0.0.12345
TEST_OPERATOR_KEY=302e020100300506032b657004220420...
TEST_MIRROR_NODES=testnet.mirrornode.hedera.com:443
```

**Result:**
- Uses mirror node address book discovery for testnet
- Economical cleanup
- Verbose logging enabled
- Parallel execution enabled

### Example 4: CI Unit Tests

```bash
# .env (or set in CI environment)
TEST_PROFILE=ciUnit
```

**Result:**
- No network required
- No operator required
- Snapshots enabled
- Sequential execution (no parallel)
- Verbose logging enabled
- No cleanup

### Example 5: CI Integration Tests

```bash
# .env (set by CI)
TEST_PROFILE=ciIntegration
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e020100300506032b657004220420...
TEST_CONSENSUS_NODES=127.0.0.1:50211
TEST_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3
TEST_MIRROR_NODES=127.0.0.1:5600
```

**Result:**
- Uses ephemeral local network (set up by CI)
- Sequential execution for stability
- Verbose logging enabled
- No cleanup (network torn down after tests)

### Example 6: Override Profile Defaults

```bash
# .env
TEST_PROFILE=local
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e020100300506032b657004220420...

# Override specific flags
TEST_VERBOSE=1
TEST_MAX_DURATION=600
TEST_CLEANUP_TOKENS=1
TEST_CLEANUP_FILES=1
```

**Result:**
- Uses `local` profile as base
- Overrides verbose logging to true
- Overrides max duration to 10 minutes
- Overrides cleanup to include tokens and files

---

## Quick Reference: Default Values

| Configuration Item | Default Value | Overridable? |
|-------------------|---------------|--------------|
| Profile | `local` | ✓ `TEST_PROFILE` |
| Environment Type | Profile-dependent | ✓ `TEST_ENVIRONMENT_TYPE` |
| Operator ID | None (required) | ✓ `TEST_OPERATOR_ID` |
| Operator Key | None (required) | ✓ `TEST_OPERATOR_KEY` |
| Consensus Nodes | `127.0.0.1:50211` (local only) | ✓ `TEST_CONSENSUS_NODES` |
| Consensus Node IDs | `0.0.3` (local only) | ✓ `TEST_CONSENSUS_NODE_ACCOUNT_IDS` |
| Mirror Nodes | `127.0.0.1:5600` (local only) | ✓ `TEST_MIRROR_NODES` |
| Network Required | Profile-dependent | ✓ `TEST_NETWORK_REQUIRED` |
| Enable Snapshots | Profile-dependent | ✓ `TEST_ENABLE_SNAPSHOTS` |
| Max Test Duration | Profile-dependent | ✓ `TEST_MAX_DURATION` |
| Parallel Execution | Profile-dependent | ✓ `TEST_PARALLEL` |
| Verbose Logging | Profile-dependent | ✓ `TEST_VERBOSE` |
| Cleanup Accounts | `true` | ✓ `TEST_CLEANUP_ACCOUNTS` |
| Cleanup Tokens | `false` | ✓ `TEST_CLEANUP_TOKENS` |
| Cleanup Files | `false` | ✓ `TEST_CLEANUP_FILES` |
| Cleanup Topics | `false` | ✓ `TEST_CLEANUP_TOPICS` |
| Cleanup Contracts | `true` | ✓ `TEST_CLEANUP_CONTRACTS` |

---

## Programmatic Documentation

You can print full documentation at runtime:

```swift
// Print all environment variables documentation
EnvironmentVariables.printDocumentation()

// Print all currently set TEST_* variables (keys redacted)
EnvironmentVariables.printAllTestVariables()
```

**Example Output:**
```
================================================================================
TEST ENVIRONMENT VARIABLES DOCUMENTATION
================================================================================

## OPERATOR
--------------------------------------------------------------------------------

TEST_OPERATOR_ID
  Type: String
  Required: ⚠ Conditional: For integration tests
  Default: None
  Description: Account ID of the operator account used for test transactions
  Example: TEST_OPERATOR_ID=0.0.1234
...
```



