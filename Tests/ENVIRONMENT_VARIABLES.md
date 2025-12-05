# Hiero SDK Swift Test Environment Variables

This document describes all environment variables that can be used to configure the test suite.

## Quick Start

For most local development, you only need:

```bash
export HIERO_OPERATOR_ID="0.0.YOUR_ACCOUNT_ID"
export HIERO_OPERATOR_KEY="YOUR_PRIVATE_KEY"
```

Or create a `.env` file in the repository root with these values (automatically loaded by the test suite).

---

## Required Variables

### `HIERO_OPERATOR_ID`

The account ID used as the operator for transactions.

| Property | Value |
|----------|-------|
| **Required** | Yes (for integration tests) |
| **Format** | Account ID string (e.g., `0.0.1234`) |
| **Example** | `HIERO_OPERATOR_ID=0.0.1001` |

### `HIERO_OPERATOR_KEY`

The private key for the operator account.

| Property | Value |
|----------|-------|
| **Required** | Yes (for integration tests) |
| **Format** | Private key string (hex or DER encoded) |
| **Example** | `HIERO_OPERATOR_KEY=302e...` |

> ⚠️ **Security Note**: Never commit operator keys to source control. Use `.env` files (gitignored) or CI secrets.

---

## Network Configuration

### `HIERO_ENVIRONMENT_TYPE`

Specifies which network environment to use.

| Property | Value |
|----------|-------|
| **Required** | No |
| **Default** | Determined by `HIERO_PROFILE` (default: `local`) |
| **Values** | `unit`, `local`, `testnet`, `previewnet`, `mainnet`, `custom` |

| Value | Description |
|-------|-------------|
| `unit` | Unit tests only, no network required |
| `local` | Local node (default for local/CI profiles) |
| `testnet` | Hedera testnet |
| `previewnet` | Hedera previewnet |
| `mainnet` | Hedera mainnet (use with caution) |
| `custom` | Custom network configuration |

### `HIERO_CONSENSUS_NODES`

Comma-separated list of consensus node addresses for local/custom networks.

| Property | Value |
|----------|-------|
| **Required** | No (uses defaults for local) |
| **Default** | `127.0.0.1:50211` (for local environment) |
| **Format** | Comma-separated `host:port` pairs |
| **Example** | `HIERO_CONSENSUS_NODES=127.0.0.1:50211,192.168.1.100:50211` |

### `HIERO_CONSENSUS_NODE_ACCOUNT_IDS`

Comma-separated list of account IDs corresponding to each consensus node.

| Property | Value |
|----------|-------|
| **Required** | No (uses defaults for local) |
| **Default** | `0.0.3` (for local environment) |
| **Format** | Comma-separated account IDs |
| **Example** | `HIERO_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3,0.0.4` |

> ⚠️ **Note**: Must have the same number of entries as `HIERO_CONSENSUS_NODES`.

### `HIERO_MIRROR_NODES`

Comma-separated list of mirror node addresses.

| Property | Value |
|----------|-------|
| **Required** | No (uses defaults for local) |
| **Default** | `127.0.0.1:5600` (for local environment) |
| **Format** | Comma-separated `host:port` pairs |
| **Example** | `HIERO_MIRROR_NODES=127.0.0.1:5600` |

---

## Test Profile

### `HIERO_PROFILE`

Selects a predefined test profile that configures multiple settings at once.

| Property | Value |
|----------|-------|
| **Required** | No |
| **Default** | `local` |
| **Values** | `local`, `ciUnit`, `ciIntegration`, `development` |

#### Profile Details

| Profile | Environment | Parallel | Verbose | Max Duration | Cleanup |
|---------|-------------|----------|---------|--------------|---------|
| `local` | `local` | No | No | 300s | Economical |
| `ciUnit` | `unit` | Yes | Yes | 120s | None |
| `ciIntegration` | `local` | Yes | Yes | 600s | None |
| `development` | `testnet` | No | Yes | 300s | Economical |

---

## Feature Flags

These can override the profile defaults.

### `HIERO_MAX_DURATION`

Maximum duration (in seconds) for a single test.

| Property | Value |
|----------|-------|
| **Required** | No |
| **Default** | `300` (or profile-specific) |
| **Format** | Number (seconds) |
| **Example** | `HIERO_MAX_DURATION=600` |

### `HIERO_PARALLEL`

Enable parallel test execution.

| Property | Value |
|----------|-------|
| **Required** | No |
| **Default** | `0` (disabled, or profile-specific) |
| **Values** | `0` (disabled), `1` (enabled) |
| **Example** | `HIERO_PARALLEL=1` |

### `HIERO_VERBOSE`

Enable verbose logging for debugging.

| Property | Value |
|----------|-------|
| **Required** | No |
| **Default** | `0` (disabled, or profile-specific) |
| **Values** | `0` (disabled), `1` (enabled) |
| **Example** | `HIERO_VERBOSE=1` |

---

## Cleanup Policy

Controls whether test resources are cleaned up after tests complete.

### `HIERO_ENABLE_CLEANUP`

Master switch for all cleanup operations (legacy variable).

| Property | Value |
|----------|-------|
| **Required** | No |
| **Default** | Not set (uses individual flags) |
| **Values** | `0` (no cleanup), `1` (full cleanup) |
| **Example** | `HIERO_ENABLE_CLEANUP=1` |

> **Note**: If set, this overrides all individual cleanup flags below.

### Individual Cleanup Flags

For fine-grained control, use these individual flags instead of `HIERO_ENABLE_CLEANUP`:

| Variable | Default | Resource Type | Notes |
|----------|---------|---------------|-------|
| `HIERO_CLEANUP_ACCOUNTS` | `1` | Accounts | **Recommended**: Recovers locked HBAR |
| `HIERO_CLEANUP_CONTRACTS` | `1` | Contracts | **Recommended**: Can recover HBAR |
| `HIERO_CLEANUP_TOKENS` | `0` | Tokens | Optional: Costs HBAR, no recovery |
| `HIERO_CLEANUP_FILES` | `0` | Files | Optional: Costs HBAR, no recovery |
| `HIERO_CLEANUP_TOPICS` | `0` | Topics | Optional: Costs HBAR, no recovery |

All cleanup flags use `0` (disabled) or `1` (enabled).

#### Predefined Cleanup Policies

The profiles use these predefined policies:

| Policy | Accounts | Contracts | Tokens | Files | Topics |
|--------|----------|-----------|--------|-------|--------|
| **None** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Economical** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **All** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Example Configurations

### Local Development (Default)

```bash
# .env file
HIERO_OPERATOR_ID=0.0.1001
HIERO_OPERATOR_KEY=302e...
```

### Local Development with Verbose Logging

```bash
HIERO_OPERATOR_ID=0.0.1001
HIERO_OPERATOR_KEY=302e...
HIERO_VERBOSE=1
```

### CI Integration Tests

```bash
HIERO_PROFILE=ciIntegration
HIERO_OPERATOR_ID=0.0.1001
HIERO_OPERATOR_KEY=302e...
```

### Testnet Development

```bash
HIERO_PROFILE=development
HIERO_OPERATOR_ID=0.0.YOUR_TESTNET_ACCOUNT
HIERO_OPERATOR_KEY=YOUR_TESTNET_KEY
```

### Custom Local Node

```bash
HIERO_ENVIRONMENT_TYPE=local
HIERO_CONSENSUS_NODES=192.168.1.50:50211
HIERO_CONSENSUS_NODE_ACCOUNT_IDS=0.0.3
HIERO_MIRROR_NODES=192.168.1.50:5600
HIERO_OPERATOR_ID=0.0.1001
HIERO_OPERATOR_KEY=302e...
```

### Full Cleanup (Local Node)

```bash
HIERO_OPERATOR_ID=0.0.1001
HIERO_OPERATOR_KEY=302e...
HIERO_ENABLE_CLEANUP=1
```

### Economical Cleanup (Testnet)

```bash
HIERO_PROFILE=development
HIERO_CLEANUP_ACCOUNTS=1
HIERO_CLEANUP_CONTRACTS=1
HIERO_CLEANUP_TOKENS=0
HIERO_CLEANUP_FILES=0
HIERO_CLEANUP_TOPICS=0
```

---

## Variable Precedence

1. **Explicit environment variable** (highest priority)
2. **Profile defaults** (from `HIERO_PROFILE`)
3. **Global defaults** (from `TestDefaults.swift`)

For example, if `HIERO_PROFILE=ciIntegration` but `HIERO_VERBOSE=0` is explicitly set, verbose logging will be disabled despite the profile enabling it.

---

## Debugging

To see all test environment variables currently set:

```swift
EnvironmentVariables.printAllTestVariables()
```

This will print all `HIERO_*` variables (with sensitive values redacted).

