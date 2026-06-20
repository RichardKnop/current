# Current

A native macOS application for managing LLM and coding-agent work across local software projects, context documents, prompts, and generated artifacts.

## Requirements

- macOS 14.0+
- Xcode 15.0+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Go 1.22+ (required from Phase 8 onwards for the agent runtime)

## Building

```bash
# Regenerate the Xcode project (run after cloning or after changing project.yml)
xcodegen generate

# Open in Xcode
open Current.xcodeproj
```

SPM dependencies (GRDB.swift) are resolved automatically by Xcode on first open.

To build from the command line:

```bash
xcodebuild -project Current.xcodeproj \
           -scheme Current \
           -configuration Debug \
           build
```

## Project guide

See [AGENTS.md](./AGENTS.md) for architecture notes, conventions, the implementation phase tracker, and guidance for AI coding agents working on this repo.
