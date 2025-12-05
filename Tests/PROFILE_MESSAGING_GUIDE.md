# Test Profile Messaging Guide

## Informative Messages When Loading Profiles

The system now provides helpful messages about which test profile is being used.

---

## Message Types

### 1. No Profile Specified (Default Used)

**When:** `TEST_PROFILE` is not set in `.env` or environment

**Visibility:** Only shown when `TEST_VERBOSE=1`

**Message:**
```
ℹ️  No TEST_PROFILE specified, using default: 'local'
```

**Example:**
```bash
# .env file (no TEST_PROFILE)
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e...

# Run with verbose
TEST_VERBOSE=1 swift test
```

**Output:**
```
ℹ️  No TEST_PROFILE specified, using default: 'local'
[tests run with local profile...]
```

---

### 2. Valid Profile Specified

**When:** `TEST_PROFILE` is set to a valid value

**Visibility:** Only shown when `TEST_VERBOSE=1`

**Valid values:**
- `local`
- `ciUnit`
- `ciIntegration`
- `development`

**Message:**
```
ℹ️  Using test profile: 'local'
```

**Example:**
```bash
# .env file
TEST_PROFILE=development
TEST_OPERATOR_ID=0.0.12345
TEST_OPERATOR_KEY=302e...

# Run with verbose
TEST_VERBOSE=1 swift test
```

**Output:**
```
ℹ️  Using test profile: 'development'
[tests run with development profile...]
```

---

### 3. Invalid Profile Specified

**When:** `TEST_PROFILE` is set to an invalid value

**Visibility:** **Always shown** (even without verbose mode)

**Message:**
```
⚠️  WARNING: Invalid TEST_PROFILE value 'typoProfile'. Valid values: local, ciUnit, ciIntegration, development
    Falling back to default profile: 'local'
```

**Example:**
```bash
# .env file
TEST_PROFILE=fullLocal  # This profile no longer exists!
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e...

# Run tests (no verbose needed)
swift test
```

**Output:**
```
⚠️  WARNING: Invalid TEST_PROFILE value 'fullLocal'. Valid values: local, ciUnit, ciIntegration, development
    Falling back to default profile: 'local'
[tests run with local profile fallback...]
```

---

## Why This Design?

### Default Message: Verbose Only
- **Rationale:** Default is `.local`, which is expected for most development
- **Benefit:** Keeps normal test output clean
- **When to use verbose:** When debugging environment setup

### Valid Profile Message: Verbose Only
- **Rationale:** Profile is correctly set, no action needed
- **Benefit:** Reduces noise in logs
- **When to use verbose:** When verifying configuration

### Invalid Profile Warning: Always Shown
- **Rationale:** This is likely a user error (typo or outdated config)
- **Benefit:** Immediately alerts user to fix their configuration
- **Action required:** Update `.env` file with valid profile name

---

## Common Scenarios

### Scenario 1: First Time Setup

```bash
# User creates .env with just operator credentials
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e...
```

**Result:**
- No message (unless verbose)
- Uses `.local` profile silently
- Everything works as expected

**To verify setup:**
```bash
TEST_VERBOSE=1 swift test
# Shows: ℹ️  No TEST_PROFILE specified, using default: 'local'
```

---

### Scenario 2: After Profile Consolidation

```bash
# User's old .env from before consolidation
TEST_PROFILE=quickLocal  # No longer valid!
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e...
```

**Result:**
```
⚠️  WARNING: Invalid TEST_PROFILE value 'quickLocal'. Valid values: local, ciUnit, ciIntegration, development
    Falling back to default profile: 'local'
```

**Action:** Update `.env` to use `TEST_PROFILE=local`

---

### Scenario 3: CI Configuration

```bash
# CI environment variables
TEST_PROFILE=ciIntegration
TEST_VERBOSE=1  # Enable verbose in CI
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e...
```

**Result:**
```
ℹ️  Using test profile: 'ciIntegration'
[CI runs integration tests with proper settings...]
```

---

### Scenario 4: Development Against Testnet

```bash
# .env for testnet development
TEST_PROFILE=development
TEST_OPERATOR_ID=0.0.12345
TEST_OPERATOR_KEY=302e...
TEST_MIRROR_NODES=testnet.mirrornode.hedera.com:443
```

**Normal run:**
```bash
swift test
# No profile message (not verbose)
```

**Verbose run:**
```bash
TEST_VERBOSE=1 swift test
# Shows: ℹ️  Using test profile: 'development'
```

---

## Updating Your Configuration

### If You See the Warning

**Before (old profile names):**
```bash
TEST_PROFILE=quickLocal   # ❌ No longer valid
# or
TEST_PROFILE=fullLocal    # ❌ No longer valid
```

**After (new profile name):**
```bash
TEST_PROFILE=local        # ✅ Use this instead
```

### Valid Profiles Quick Reference

| Profile | Purpose | When to Use |
|---------|---------|-------------|
| `local` | Local development | Default for all local testing |
| `ciUnit` | CI unit tests | CI pipeline, unit tests only |
| `ciIntegration` | CI integration tests | CI pipeline, integration tests |
| `development` | Remote environments | Testing against testnet/previewnet |

---

## Environment Variable Precedence

1. **Explicit environment variable** (highest priority)
   ```bash
   TEST_PROFILE=development swift test
   ```

2. **`.env` file** (loaded by DotenvLoader)
   ```bash
   # .env
   TEST_PROFILE=local
   ```

3. **Default** (lowest priority)
   - If neither above is set: defaults to `local`

---

## Debugging Profile Issues

### Check Current Profile

**With verbose:**
```bash
TEST_VERBOSE=1 swift test --filter SomeTest
```

**Look for:**
```
ℹ️  Using test profile: 'YOUR_PROFILE'
```

### Verify Profile Settings

**In code/test:**
```swift
print("Profile: \(config.profile)")
print("Environment Type: \(config.type)")
print("Network Required: \(config.features.networkRequired)")
```

### Print All Environment Variables

**In code/test:**
```swift
EnvironmentVariables.printAllTestVariables()
```

**Output:**
```
=== Test Environment Variables ===
TEST_OPERATOR_ID = 0.0.2
TEST_OPERATOR_KEY = ***REDACTED***
TEST_PROFILE = local
...
==================================
```

---

## Best Practices

1. **For local development:** Omit `TEST_PROFILE` or set to `local`
2. **For CI:** Always explicitly set profile (`ciUnit` or `ciIntegration`)
3. **For testnet/previewnet:** Set `TEST_PROFILE=development`
4. **When debugging:** Use `TEST_VERBOSE=1` to see what's happening
5. **After updates:** Check for warnings about invalid profiles

---

## Summary

✅ **Default behavior:** Silent when using `.local` (the default)  
✅ **Valid profile:** Shown in verbose mode for confirmation  
✅ **Invalid profile:** Always warns and suggests valid values  
✅ **Helpful guidance:** Clear next steps when something is wrong

This messaging system helps you understand what's happening without cluttering your test output unnecessarily.



