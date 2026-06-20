# Current — Architecture

## Product Direction

Current is a native macOS application for managing LLM and coding-agent work across local software projects, document corpora, prompts, chat history, agent runs, and generated artifacts.

> **Name note:** "Current" is the working name (water current → workflow). It may be renamed before release. See the "App Name" section under Technology Choices for how to keep a rename low-effort.

The first version should feel familiar to users of Codex or Claude Code desktop apps: a project sidebar, a project-scoped chat area, settings for providers/models, and persistent local state. The longer-term goal is broader than chat. The durable product object is an agent run:

```text
project state + selected context + prompt + provider/model + tools -> artifacts
```

Artifacts may include diffs, generated files, command outputs, reports, screenshots, summaries, or workflow outputs worth saving and sharing.

## High-Level Architecture

```text
Current.app (SwiftUI macOS app)
  - Native UI
  - Navigation
  - settings screens
  - project and document management
  - chat/run presentation
  - local persistence access
  - secure credential storage

Embedded database
  - SQLite for the first version
  - MiniSQL-compatible storage abstraction later

Go helper runtime (agent-runtime binary)
  - Long-running local process
  - provider adapters
  - filesystem and git tools
  - future shell/tool execution
  - agent run orchestration
  - stdio newline-delimited JSON-RPC 2.0

Optional TypeScript/Python sidecars
  - Only if a vendor SDK has important capabilities unavailable or impractical in Go
```

## Technology Choices

### App Name

The working name is **Current**. It may be renamed before release.

To keep a future rename cheap:

- The display name (`CFBundleDisplayName`) and bundle ID (`CFBundleIdentifier`) live only in the Xcode project's target settings and `Info.plist`. Changing them is a two-field edit.
- Never hardcode the string `"Current"` as a user-visible label in Swift source. Derive it from `Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")` or a single `AppInfo.swift` constants file.
- The Xcode project file itself is named `Current.xcodeproj` and the Swift target is `Current`. Renaming those requires an Xcode rename + a handful of `git mv` calls — annoying but mechanical. Don't let this block work.
- The Go binary is named `agent-runtime`, not `current-runtime`, so it needs no rename.

Bundle ID for the working name: `com.richardknop.current`.

### macOS App

Use Swift and SwiftUI for the native application.

Reasons:

- Best fit for macOS navigation, windows, menus, settings, drag and drop, file pickers, sandbox permissions, and Keychain integration.
- Better native feel than Electron.
- Good path to a polished long-lived desktop product.
- AppKit can be used selectively where SwiftUI is too limited.

### Local Runtime

Use Go for the local helper process.

Reasons:

- Single native binary.
- Fast startup and low memory overhead.
- Strong filesystem, process, HTTP, and concurrency support.
- Natural fit for git and local project operations.
- Aligns well with possible future MiniSQL integration.

The Go helper should not be required for the first UI-only milestone. Introduce it when chats, agent runs, tool calls, or provider integration begin.

### IPC Protocol

Use **stdio with newline-delimited JSON-RPC 2.0** for communication between the Swift app and the Go helper.

Reasons:

- No network socket or network entitlement required.
- No cleanup needed on crash; the OS reclaims stdio pipes.
- Easy to test manually (`echo '{"jsonrpc":"2.0",...}' | ./agent-runtime`).
- Well-established prior art in the Language Server Protocol.

The Swift app launches the Go binary as a child process. The app writes JSON-RPC requests to the process's stdin; the Go helper writes responses and server-side notifications to stdout. Stderr is for diagnostic logs only and is never parsed by the Swift side.

The canonical message schema lives in `Shared/protocol/messages.schema.json` and is the source of truth for both sides.

### Database

Start with SQLite.

Reasons:

- Mature and reliable for local app state.
- Excellent fit for structured app data plus full-text search later.
- Easy to inspect during development.
- Good Swift library support.

Recommended Swift library: GRDB.swift.

MiniSQL can be introduced later behind a storage abstraction once the app's data model is stable.

### Provider Integration

The app should not be designed around one provider's chat shape. Instead, model providers by capabilities:

```text
Provider capabilities:
  - text generation
  - streaming
  - tool calling
  - structured output
  - file editing
  - shell execution
  - hosted sandbox
  - local filesystem agent
```

OpenAI and Anthropic both support tool-oriented workflows, but the app should own durable state, approvals, run history, and artifacts.

## Core Concepts

### Project

A project represents a local folder, usually a git repository, containing chats and agent runs.

Projects are stored in the app database, but the source files remain in their original filesystem locations.

Initial fields:

```text
id
name
folder_path
created_at
last_opened_at
git_enabled
```

### Document Library

The document library is a reusable global corpus of context documents such as Markdown files, design docs, SQL files, specs, notes, and snippets.

The app should also support project-scoped documents later. The first document implementation can start with a global library and project/chat attachments.

Imported global documents should be copied into the app support directory so they remain available between launches.

### Prompt Library

Prompts are reusable instructions that can be global or project-scoped.

Prompt versioning is desirable, but does not need to exist in the first UI milestone.

### Chat

A chat belongs to one project.

Chats should persist full message history locally. A chat may have selected context documents and a selected provider/model.

Chats can be added after project CRUD and document library functionality exists.

### Agent Run

An agent run is a single execution initiated from a chat or workflow.

Runs should store:

- selected provider/model
- input message
- selected context
- streamed assistant output
- tool calls
- approvals
- command output
- generated artifacts
- before/after git state

This is the main concept that distinguishes the app from a plain chat client.

### Artifact

Artifacts are durable outputs of runs.

Examples:

- git diff
- generated file
- saved report
- command output
- test result
- exported Markdown
- screenshot
- workflow result

Artifacts should be stored locally and referenced from the database.

## Initial Database Model

First UI-only milestones need only a subset:

```text
projects
settings
provider_configs
```

Near-term tables:

```text
projects
documents
project_documents
prompts
chats
chat_documents
messages
agent_runs
tool_calls
artifacts
```

Suggested project table:

```sql
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  folder_path TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  last_opened_at TEXT,
  git_enabled INTEGER NOT NULL DEFAULT 0
);
```

## Filesystem Layout

Suggested app support layout:

```text
~/Library/Application Support/Current/
  app.sqlite
  Corpus/
    <document-id>/
      original
      metadata.json
  Artifacts/
    <artifact-id>/
      payload
      metadata.json
  Logs/
```

The Application Support directory name is derived from the bundle identifier at runtime — it is not hardcoded as a string in source. If the app is renamed, this path changes automatically.

Project source folders stay wherever the user selected them.

## Settings And Credentials

Settings stored in SQLite:

- enabled providers
- selected default provider
- selected default model
- UI preferences
- runtime preferences

Secrets stored in Keychain:

- OpenAI API key
- Anthropic API key
- future provider credentials

Never store raw API keys in SQLite.

## Git Integration

For the first implementation, use the git CLI rather than libgit2.

The app should eventually expose:

- current branch
- dirty status
- diff
- branch switching
- commit creation
- revert/discard flow with explicit confirmation

Agent runs should capture before/after git state so the UI can explain what changed.

## Security And Permissions

The app should be conservative with local access.

Important principles:

- The user explicitly selects project folders.
- The app should track which folders are allowed.
- Tool execution should require approval policies.
- Destructive operations need explicit confirmation.
- Secrets belong in Keychain.
- Agent tool calls should be logged.

### macOS Sandbox And Security-Scoped Bookmarks

The app must be sandboxed (required for Keychain access and App Store distribution, and correct practice regardless).

A sandboxed app cannot access arbitrary filesystem paths after restart unless it persists Security-Scoped Bookmarks. When the user selects a project folder via `NSOpenPanel`, the app must:

1. Call `url.bookmarkData(options: .withSecurityScope, ...)` immediately after the panel returns.
2. Store the bookmark data blob in the `projects` table alongside `folder_path`.
3. On every subsequent launch, resolve the bookmark and call `startAccessingSecurityScopedResource()` before reading any files in that folder.
4. Call `stopAccessingSecurityScopedResource()` when the project is closed or the app quits.

This is not optional. Without it, the app will work in development (where the sandbox is typically bypassed) but fail silently in a production or TestFlight build.

## Deferred Decisions

These should not block the first skeleton:

- Exact Go helper protocol.
- OpenAI vs Anthropic implementation details.
- MiniSQL integration.
- Real-time collaboration backend.
- External sharing format for artifacts.
- Workflow graph editor.
- Full prompt versioning.
- Sandboxed execution strategy for shell commands.

