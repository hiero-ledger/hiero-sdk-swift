# Environment Variable Rename: `TEST_*` → `HIERO_*`

## Summary

All test environment variables have been renamed from `TEST_*` to `HIERO_*` for better branding and namespace clarity.

## Migration Required

**You must update your `.env` file!** Here's the mapping:

### Operator Configuration
| Old Name | New Name |
|----------|----------|
| `TEST_OPERATOR_ID` | `HIERO_OPERATOR_ID` |
| `TEST_OPERATOR_KEY` | `HIERO_OPERATOR_KEY` |

### Network Configuration
| Old Name | New Name |
|----------|----------|
| `TEST_ENVIRONMENT_TYPE` | `HIERO_ENVIRONMENT_TYPE` |
| `TEST_CONSENSUS_NODES` | `HIERO_CONSENSUS_NODES` |
| `TEST_CONSENSUS_NODE_ACCOUNT_IDS` | `HIERO_CONSENSUS_NODE_ACCOUNT_IDS` |
| `TEST_MIRROR_NODES` | `HIERO_MIRROR_NODES` |

### Test Profile
| Old Name | New Name |
|----------|----------|
| `TEST_PROFILE` | `HIERO_PROFILE` |

### Feature Flags
| Old Name | New Name |
|----------|----------|
| `TEST_MAX_DURATION` | `HIERO_MAX_DURATION` |
| `TEST_PARALLEL` | `HIERO_PARALLEL` |
| `TEST_VERBOSE` | `HIERO_VERBOSE` |

### Cleanup Policy
| Old Name | New Name |
|----------|----------|
| `TEST_ENABLE_CLEANUP` | `HIERO_ENABLE_CLEANUP` |
| `TEST_CLEANUP_ACCOUNTS` | `HIERO_CLEANUP_ACCOUNTS` |
| `TEST_CLEANUP_TOKENS` | `HIERO_CLEANUP_TOKENS` |
| `TEST_CLEANUP_FILES` | `HIERO_CLEANUP_FILES` |
| `TEST_CLEANUP_TOPICS` | `HIERO_CLEANUP_TOPICS` |
| `TEST_CLEANUP_CONTRACTS` | `HIERO_CLEANUP_CONTRACTS` |

## Example .env File Update

### Before
```bash
TEST_OPERATOR_ID=0.0.2
TEST_OPERATOR_KEY=302e020100300506032b65700422042091132178e72057a1d7528025956fe39b0b847f200ab59b2fdd367017f3087137
TEST_PROFILE=local
TEST_VERBOSE=1
```

### After
```bash
HIERO_OPERATOR_ID=0.0.2
HIERO_OPERATOR_KEY=302e020100300506032b65700422042091132178e72057a1d7528025956fe39b0b847f200ab59b2fdd367017f3087137
HIERO_PROFILE=local
HIERO_VERBOSE=1
```

## Quick Migration Script

Run this in your terminal from the repo root:

```bash
# Backup your current .env file
cp .env .env.backup

# Replace TEST_ with HIERO_ in .env
sed -i '' 's/TEST_/HIERO_/g' .env

# Verify the changes
diff .env.backup .env
```

## CI/CD Updates

If you have environment variables set in your CI/CD system (GitHub Actions, etc.), update them there too:

### GitHub Actions Example
```yaml
# Before
env:
  TEST_OPERATOR_ID: ${{ secrets.TEST_OPERATOR_ID }}
  TEST_OPERATOR_KEY: ${{ secrets.TEST_OPERATOR_KEY }}

# After
env:
  HIERO_OPERATOR_ID: ${{ secrets.HIERO_OPERATOR_ID }}
  HIERO_OPERATOR_KEY: ${{ secrets.HIERO_OPERATOR_KEY }}
```

## Why This Change?

✅ **Better branding** - Clearly associated with Hiero SDK  
✅ **Namespace clarity** - Avoids conflicts with generic `TEST_*` vars from other tools  
✅ **Professional** - Project-specific naming convention  
✅ **Consistency** - Matches Hiero SDK naming  

## Files Changed

- `Tests/HieroTestSupport/Environment/EnvironmentVariables.swift`
- `Tests/HieroTestSupport/Environment/DotenvLoader.swift`
- `Tests/HieroTestSupport/Environment/EnvironmentValidation.swift`
- `Tests/HieroTestSupport/Environment/FeatureFlags.swift`
- `Tests/HieroTestSupport/Environment/TestProfile.swift`

All environment variable references updated consistently across the codebase.

## Verification

After updating your `.env` file, verify it works:

```bash
# Should show your variables with HIERO_ prefix
HIERO_VERBOSE=1 swift test --filter "AccountBalance.testQuery$"
```

If you see "Loaded environment variables" in the output, your `.env` file is being read correctly.

