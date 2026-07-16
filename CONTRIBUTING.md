# Contributing to Narration Pilot

Thanks for helping improve Narration Pilot.

## Development setup

1. Install Xcode and the Xcode Command Line Tools.
2. Clone the repository.
3. Run `swift build` from the repository root.
4. Launch the current debug build with `./scripts/dev-run.sh`.

## Before opening a pull request

- Keep changes focused and explain the user-facing reason for them.
- Run `swift build` and `swift build -c release`.
- Run `swift test` when XCTest is available in your Swift toolchain.
- Do not commit API keys, credentials, personal scripts, or generated build artifacts.
- Update the README when behavior or setup instructions change.

Please open an issue before starting a large architectural change so the approach can be discussed first.
