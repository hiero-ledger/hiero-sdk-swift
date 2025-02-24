# Release process for SWIFT SDK

## Release
1. Create a new git branch: `release/vX.Y.Z`.
>- Follows [semver 2.0](https://semver.org/spec/v2.0.0.html)
2. Run all tests against [hiero-local-node](https://github.com/hiero-ledger/hiero-local-node). Stop local-node once the tests are completed.
>- `swift test`
3. Create a new tag.
>- `git push -a <version> -m <version>`
4. Once branch has been approved and merged to main, document added features pertaining to the newest release.
>- [Tags and Releases for Swift SDK](https://github.com/hiero-ledger/hiero-sdk-swift/releases)