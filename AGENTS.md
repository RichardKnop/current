# AGENTS.md — Current App Codebase Guide

This file is the single source of truth for all AI coding agents (Claude Code, Codex, etc.) working on this repository. `CLAUDE.md` redirects here. Do not duplicate content between the two files.

---

## Project Overview

**Current** is a native macOS application for managing LLM and coding-agent work. Users can organize local projects (git repositories or folders), manage reusable context documents and prompts, run chat and agent workflows against multiple providers, and accumulate durable artifacts from each run.

> **Name note:** "Current" is the working name and may be renamed before release. See the App Name section below for how to keep that rename cheap.

See `docs/architecture.md` for the full design. See `docs/implementation-plan.md` for the phased delivery plan.

---

## Repository Layout

```
current/                             <- repo root (github.com/RichardKnop/current)
  Current.xcodeproj                  <- Xcode project (created in Phase 1)
  Current/                           <- Swift app sources
    App/                             <- @main entry point, AppDelegate if needed
    UI/                              <- SwiftUI views, organized by feature
    Models/                          <- value types and domain models (structs)
    Stores/                          <- database access (GRDB-based repositories)
    Services/                        <- business logic, not tied to UI or DB
    Runtime/                         <- Go helper process manager and IPC client
    Documents/                       <- document import and storage
    Settings/                        <- settings model and Keychain integration
    Git/                             <- git CLI wrapper
    Resources/                       <- assets, entitlements, Info.plist
  AgentRuntime/                      <- Go helper process
    go.mod
    cmd/
      agent-runtime/                 <- main package (binary name is agent-runtime, not current)
    internal/
      protocol/                      <- JSON-RPC message types
      providers/                     <- OpenAI, Anthropic adapters
      tools/                         <- file, git, shell tool implementations
      runs/                          <- run orchestration
  Shared/
    protocol/
      messages.schema.json           <- canonical message schema (source of truth)
  docs/
    architecture.md
    implementation-plan.md
  AGENTS.md
  CLAUDE.md
```

> **Note:** `Current.xcodeproj` and the `Current/` source directory do not exist until Phase 1 is complete. `AgentRuntime/` does not exist until Phase 8.

---

## App Name And Renaming

The working name is **Current**. It may be renamed before release.

Rules to keep a future rename cheap:

- **Never hardcode the string `"Current"` as a user-visible label** in Swift source files. All user-visible references to the app name must come from one of:
  - `Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String`
  - A single `AppInfo.swift` constants file that reads from `Bundle.main`
- The display name and bundle ID live only in the Xcode target settings (`Info.plist` / Build Settings). Changing the name is a two-field edit there.
- The Application Support path (`~/Library/Application Support/Current/`) is derived at runtime from the bundle name — do not construct it with a hardcoded `"Current"` path component. Use `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)`.
- The Go binary is named `agent-runtime` (not `current-runtime`), so it needs no rename.
- The Xcode project file and Swift target are named `Current`. Renaming them later is mechanical (`git mv` + Xcode rename) but not blocking for any feature work.

Current bundle ID: `com.richardknop.current`

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| macOS app | Swift 5.10+, SwiftUI | Target macOS 14 (Sonnet) or later |
| Local DB | SQLite via GRDB.swift | Added via Swift Package Manager |
| Credentials | Keychain (Security framework) | Never store API keys in SQLite |
| Go helper | Go 1.22+ | Single binary, stdio JSON-RPC 2.0 |
| IPC protocol | Newline-delimited JSON-RPC 2.0 | Same shape as LSP; no network socket needed |
| Git | `git` CLI (subprocess) | No libgit2 in v1 |
| Providers | OpenAI, Anthropic REST APIs | Go helper handles all provider calls |

---

## Build and Run

### macOS App (Phase 1+)

`Current.xcodeproj` is **generated** from `project.yml` using [xcodegen](https://github.com/yonaskolb/XcodeGen). Never edit `.pbxproj` directly — it will be overwritten.

```bash
# Regenerate the Xcode project after changing project.yml
xcodegen generate

# Open in Xcode
open Current.xcodeproj

# Build from command line (requires Xcode, not just Command Line Tools)
xcodebuild -project Current.xcodeproj \
           -scheme Current \
           -configuration Debug \
           build
```

When to run `xcodegen generate`:
- After modifying `project.yml` (new targets, schemes, build settings)
- After cloning the repo (`.xcodeproj` is committed but this ensures it is fresh)

Minimum deployment target: **macOS 14.0**.

### Go Helper (Phase 8+)

```bash
cd AgentRuntime
go build ./cmd/agent-runtime/...
go test ./...
```

Go version is pinned in `AgentRuntime/go.mod`. Do not upgrade Go without updating CI.

### Running Tests

```bash
# Swift tests
xcodebuild test -project Current.xcodeproj -scheme Current -destination 'platform=macOS'

# Go tests
cd AgentRuntime && go test ./...
```

---

## Implementation Phase Tracker

Update the status column as phases are completed. Do not skip phases or start a later phase before the earlier one's acceptance criteria are met.

| Phase | Name | Status |
|---|---|---|
| 0 | Planning artifacts | **complete** |
| 1 | Native macOS app skeleton | **complete** |
| 2 | SQLite persistence | **complete** |
| 3 | Project CRUD | **complete** |
| 4 | Settings page | **in progress** |
| 5 | Global document library | not started |
| 6 | Prompt library | not started |
| 7 | Chat shell (no providers) | not started |
| 8 | Go helper skeleton | not started |
| 9 | Provider API integration | not started |
| 10 | Tool calling and file-aware agents | not started |
| 11 | Artifacts and run history | not started |
| 12 | Workflow layer | not started |

---

## Swift Conventions

- **SwiftUI first**; reach for AppKit only when SwiftUI cannot do the job.
- Use `NavigationSplitView` for the three-column layout (sidebar / content / detail).
- Use `@Observable` (Swift 5.9 macro) for view models, not `ObservableObject`/`@Published`.
- Domain models are plain `struct` types. No business logic in SwiftUI views.
- Database access goes through store types in `Stores/`. Views never call GRDB directly.
- Use `async/await` for all async work. No Combine pipelines unless forced by a framework.
- Errors surface via `Result` or thrown errors; never silently swallowed.
- **No raw API keys in code, plists, or SQLite.** Keys go in Keychain only.

### Naming

- Views: noun + `View` suffix (`ProjectListView`, `ChatView`).
- View models: noun + `Model` suffix (`ProjectListModel`).
- Stores: noun + `Store` suffix (`ProjectStore`).
- Services: noun + `Service` suffix (`ProviderService`).

### macOS Sandbox

The app must be sandboxed. This has two important consequences:

1. **Entitlements** — the entitlements file must declare `com.apple.security.app-sandbox = YES` and any other capabilities used (network client, file access).
2. **Security-Scoped Bookmarks** — when the user selects a project folder via `NSOpenPanel`, persist the resulting Security-Scoped Bookmark data in SQLite alongside the project record. Resolve and start accessing the bookmark on every app launch. Without this, the app cannot reopen project folders after restart in a sandboxed build.

```swift
// Save when user picks a folder
let bookmarkData = try url.bookmarkData(
    options: .withSecurityScope,
    includingResourceValuesForKeys: nil,
    relativeTo: nil
)
// Store bookmarkData in projects table

// Restore on launch
var isStale = false
let resolvedURL = try URL(
    resolvingBookmarkData: bookmarkData,
    options: .withSecurityScope,
    relativeTo: nil,
    bookmarkDataIsStale: &isStale
)
resolvedURL.startAccessingSecurityScopedResource()
```

---

## Go Conventions

- All packages under `AgentRuntime/internal/` — nothing in internal is imported outside the module.
- Exported types only in `cmd/` main packages and any future shared library.
- Use `context.Context` as the first argument on any function that does I/O.
- Errors are returned, not panicked (except programmer errors at init time).
- Use `slog` for structured logging.
- Provider adapters implement a common `Provider` interface; no provider-specific types leak into `runs/`.

### JSON-RPC Protocol

The Swift app launches the Go binary as a child process and communicates over **stdio**:

- Each message is one JSON line terminated by `\n` (no length prefix).
- Uses [JSON-RPC 2.0](https://www.jsonrpc.org/specification).
- Swift writes requests to the process's stdin; Go writes responses and notifications to stdout.
- Stderr is for diagnostic logs only (never parsed by Swift).
- The canonical message schema lives in `Shared/protocol/messages.schema.json`. Both sides must stay in sync with it.

Required initial methods:
- `ping` → `pong`
- `list_capabilities`
- `start_run` (params: run config)
- `cancel_run` (params: run id)

Notifications (server → client, no id):
- `run.event` (streaming output, tool calls, status updates)
- `run.complete`
- `run.error`

---

## Database Conventions

- All migrations live in the `Stores/Migrations/` directory as numbered Swift files (`001_initial.swift`, `002_add_documents.swift`, etc.).
- Migrations run in order on every app launch; the GRDB migrator ensures each runs only once.
- Use `TEXT` for UUIDs stored as strings. Use `TEXT` for timestamps in ISO 8601 format.
- Never store secrets (API keys, tokens) in SQLite.
- Schema changes always go through a new migration — never mutate existing migration files.
- Add a new migration file for every schema change, no matter how small.

---

## Security Rules

These are hard rules, not suggestions:

- API keys live in Keychain only. Never in SQLite, plists, environment variables baked into the binary, or logs.
- Tool execution (shell commands, file writes) requires an explicit approval record in the `tool_calls` table before the action runs.
- Destructive operations (file deletion, git reset) require an additional confirmation step in the UI.
- Log every tool call attempt, approval or denial, and outcome.
- The app does not execute arbitrary code from provider responses. Tool calls are dispatched through a known, enumerated set of tool handlers.

---

## Agent Guidance

### Implementation notes

**Settings placement:** The implementation plan listed "Settings" as a sidebar item. Settings is instead implemented as a standard macOS `Settings {}` scene, opened via `Cmd+,`. This is the macOS HIG-compliant convention and keeps the sidebar focused on content navigation. The `SettingsView` placeholder lives in `Current/UI/Settings/`.

### Where to start

Always begin from the **lowest incomplete phase** in the phase tracker above. Do not jump ahead. If Phase 2 acceptance criteria are not all met, do not begin Phase 3 work.

### Incremental loop

For every task within a phase:

1. Make the smallest change that satisfies one acceptance criterion.
2. Build successfully.
3. Run and verify the behavior manually or via tests.
4. Commit.

### What not to do

- Do not start provider API calls before Phase 9.
- Do not add the Go helper before Phase 8.
- Do not store API keys outside Keychain for any reason, including tests.
- Do not add Combine pipelines; use `async/await`.
- Do not add embeddings, semantic search, or PDF support before Phase 5's basic flow is working.
- Do not modify existing migration files — always add new ones.
- Do not delete project source folders from disk. The app manages its own database records only.
- Do not use force-push or amend published commits.

### When adding a new provider

Provider adapters live in `AgentRuntime/internal/providers/`. Each adapter implements the shared `Provider` interface. No provider-specific types should appear in `runs/`, `protocol/`, or the Swift app. All provider credentials are fetched from the Swift side at run start time and passed to the Go helper as part of the run config — the Go helper never reads the Keychain directly.

### Updating this file

Update the phase tracker status when a phase is complete. Add sections as new technology is introduced. Keep build commands current.

---

## References

- `docs/architecture.md` — design decisions and rationale
- `docs/implementation-plan.md` — phased delivery plan with acceptance criteria
- `requirement.md` — original product brief (delete once implementation begins)
