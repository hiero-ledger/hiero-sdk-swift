# Contributing to the Hiero SDK for Swift

Thank you for your interest in contributing the Hiero SDK for Swift!

We appreciate your interest in helping us and the rest of our community. We welcome bug reports, feature requests, and
code contributions.

**Jump To:**
- [Code Contributions](#code-contributions)
- [Bug Reports](#bug-reports)
- [Feature Requests](#feature-requests)

## Code Contributions

1. Get assigned to an [Open Swift SDK Issue](https://github.com/hiero-ledger/hiero-sdk-swift/issues?q=is%3Aissue%20state%3Aopen%20no%3Aassignee)
2. Solve the issue and create a pull request following the [Workflow Guide](docs/training/workflow.md)

For detailed guidance on the contribution process, see our training documentation:
- [Workflow Guide](docs/training/workflow.md) - Complete contribution workflow
- [Signing Guide](docs/training/signing.md) - DCO and GPG commit signing
- [Rebasing Guide](docs/training/rebasing.md) - Keeping your branch up to date
- [Merge Conflicts Guide](docs/training/merge-conflicts.md) - Resolving conflicts

Note:
- The SDK is released under the [Apache 2.0 License][license]. Any code you submit will be released under this license.

## Feature Requests

**NOTE:** If you intend to implement a feature request, please submit the feature request _before_ working on any code
changes and ask to get assigned.

1. Visit [Swift SDK Issues](https://github.com/hiero-ledger/hiero-sdk-swift/issues)
2. Verify the Feature Request is not already proposed.
2. Click 'New Issue' and click the Feature Request template.
**Ensure** the [enhancement][label-enhancement] label is attached.

### Submitting a Feature Request

Open an [issue][issues] with the following:

- A short, descriptive title. Other community members should be able to understand the nature of the issue by reading
  this title.
- A detailed description of the the proposed feature. Explain why you believe it should be added to the SDK.
  Illustrative example code may also be provided to help explain how the feature should work.
- [Markdown][markdown] formatting as appropriate to make the request easier to read.
- If you plan to implement this feature yourself, please let us know that you'd like to the issue to be assigned to you.

## Bug Reports

⚠️ **Ensure you are using the latest release of the SDK**.

It's possible the bug is already fixed. We will do our utmost to maintain backwards compatibility between patch version releases, so that you can be
   confident that your application will continue to work as expected with the newer version.

1. Visit [Swift SDK Issue Page](https://github.com/hiero-ledger/hiero-sdk-swift/issues)
2. ⚠️ **Check the Bug is not Already Reported**. If it is, comment to confirm you are also experiencing this bug.
3. Click 'New Issue' and choose the `Bug Report` template

**Ensure** the [bug][label-bug] label is attached.

Please ensure that your bug report contains the following:

- A short, descriptive title. Other community members should be able to understand the nature of the issue by reading
  this title.
- A succinct, detailed description of the problem you're experiencing. This should include:
  - Expected behavior of the SDK and the actual behavior exhibited.
  - Any details of your application development environment that may be relevant.
  - If applicable, the exception stack-trace.
  - If you are able to create one, include a [Minimal Working Example][mwe] that reproduces the issue.
- [Markdown][markdown] formatting as appropriate to make the report easier to read; for example use code blocks when
  pasting a code snippet or exception stack-trace.

[issues]: https://github.com/hiero-ledger/hiero-sdk-swift/issues
[label-bug]: https://github.com/hiero-ledger/hiero-sdk-swift/labels/bug
[label-enhancement]: https://github.com/hiero-ledger/hiero-sdk-swift/labels/enhancement
[mwe]: https://en.wikipedia.org/wiki/Minimal_Working_Example
[markdown]: https://guides.github.com/features/mastering-markdown/
[license]: https://github.com/hiero-ledger/hiero-sdk-swift/blob/main/LICENSE
