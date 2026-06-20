# Current — Implementation Plan

## Guiding Strategy

Build the app in thin vertical slices. Start with native UI, local persistence, and project management before introducing provider APIs or agent execution.

The first useful milestone is a macOS app that can:

- launch reliably
- persist local state
- create and delete projects
- open a project from the sidebar
- show settings
- survive quit/reopen with the same state

Chats and agent runtime should come later, after the app shell and database are boringly solid.

## Phase 0: Planning Artifacts

Status: complete when architecture and implementation docs exist.

Deliverables:

- `docs/architecture.md`
- `docs/implementation-plan.md`

Acceptance criteria:

- Another agent can understand the intended architecture without reading the original conversation.
- Major deferred decisions are explicitly marked.

## Phase 1: Native macOS App Skeleton

Goal: create a minimal SwiftUI macOS app that launches and has the intended navigation structure.

Tasks:

1. Create the Xcode project.
2. Add a SwiftUI app target.
3. Set bundle identifier (`com.richardknop.current`), display name (`Current`), and macOS deployment target (14.0).
4. Add entitlements file with `com.apple.security.app-sandbox = YES` and `com.apple.security.network.client = YES`.
5. Add a three-area layout:
   - left sidebar
   - main content area
   - optional detail/inspector placeholder
6. Add sidebar navigation:
   - Projects
   - Library
   - Prompts
   - Settings
7. Add empty states for each section.

Acceptance criteria:

- App builds and launches.
- Sandbox entitlements file is present.
- Sidebar navigation works.
- No database or external services required yet.
- Empty project state is clearly represented.

Recommended first UI model:

```text
NavigationSplitView
  Sidebar
  Content
```

## Phase 2: SQLite Persistence

Goal: add durable local state with SQLite.

Tasks:

1. Add GRDB.swift dependency.
2. Create database location under Application Support.
3. Create migration system.
4. Add initial schema:
   - projects
   - app_settings
   - provider_configs placeholder
5. Add a small repository/store layer:
   - `ProjectStore`
   - `SettingsStore`
6. Add app startup database initialization.

Acceptance criteria:

- Database file is created in Application Support.
- Migrations run once and are repeatable.
- App can write and read a test setting.
- App still launches when database already exists.

## Phase 3: Project CRUD

Goal: user can create, list, open, and delete projects.

Tasks:

1. Add project model.
2. Add project list in sidebar.
3. Add create project flow:
   - choose existing folder via `NSOpenPanel`
   - create new folder
4. Persist Security-Scoped Bookmark data alongside `folder_path` in SQLite.
5. On app launch, resolve and start accessing bookmarks for all stored projects.
6. Store project metadata in SQLite.
7. Detect whether selected folder is a git repository.
8. Add delete project flow:
   - removes project from app database
   - stops accessing security-scoped resource
   - does not delete the folder from disk
9. Add last-opened tracking.

Acceptance criteria:

- First launch shows no projects.
- User can add an existing folder as a project.
- User can create a new folder as a project.
- Projects remain visible after app restart.
- App can reopen a project folder after restart without prompting the user again (Security-Scoped Bookmark resolved successfully).
- Deleting a project removes it from the app only.
- Git repository detection works at least by checking `.git`.

Important UX decision:

Deleting a project should not delete source files. Use wording like "Remove from App" rather than "Delete Folder".

## Phase 4: Settings Page

Goal: create the initial settings surface for providers and models without making API calls.

Tasks:

1. Build settings page.
2. Add provider sections:
   - OpenAI
   - Anthropic
3. Add API key fields.
4. Store API keys in Keychain.
5. Store enabled provider/model metadata in SQLite.
6. Add default provider/model selection.
7. Add validation states:
   - not configured
   - configured locally
   - validation pending future API integration

Acceptance criteria:

- User can enter and save provider settings.
- API keys are not stored in SQLite.
- Settings survive app restart.
- Project/chat areas can read configured provider availability.

Deferred:

- Live API key validation.
- Model listing from provider APIs.
- OAuth or account-based auth.

## Phase 5: Global Document Library

Goal: allow users to import reusable context documents.

Tasks:

1. Add document schema.
2. Add Library screen.
3. Add import flow for:
   - Markdown
   - text
   - code files
   - SQL files
   - JSON/YAML
4. Copy imported documents into Application Support.
5. Store metadata:
   - title
   - original path
   - stored path
   - content hash
   - MIME/type hint
   - size
   - created date
6. Add delete/remove document flow.
7. Add simple document preview.

Acceptance criteria:

- User can import documents into global library.
- Imported documents survive app restart.
- Removing a document removes it from the library and app-managed storage.
- Original source file is not modified.

Deferred:

- Embeddings.
- Semantic search.
- Chunking.
- OCR/PDF support.
- Project-scoped document copies.

## Phase 6: Prompt Library

Goal: store reusable prompts before chat execution exists.

Tasks:

1. Add prompt schema.
2. Add Prompts screen.
3. Add create/edit/delete prompt flows.
4. Support global prompts first.
5. Add optional project association later.

Acceptance criteria:

- User can create and edit prompts.
- Prompts persist after restart.
- Prompt list is available from the sidebar.

Deferred:

- Prompt versioning.
- Prompt templates with variables.
- Prompt test runs.

## Phase 7: Chat Shell Without Providers

Goal: create the project-scoped chat UI and local message persistence without API calls.

Tasks:

1. Add chat schema.
2. Add message schema.
3. Add project detail screen with chat list.
4. Add new chat flow.
5. Allow attaching documents from the library to a chat.
6. Add model dropdown using configured settings.
7. Disable composer if no provider/model is configured.
8. Store user-authored messages locally.
9. Add placeholder assistant response for local UI testing only.

Acceptance criteria:

- User can create chats inside projects.
- Chat history persists after restart.
- Chat composer is disabled without configured model.
- Chat can display selected context documents.

Deferred:

- Real provider calls.
- Streaming.
- Tool calls.
- Go helper.
- Agent run artifacts.

## Phase 8: Go Helper Skeleton

Goal: introduce the local runtime process without external provider integration.

Tasks:

1. Create Go module under `AgentRuntime/`.
2. Define protocol messages using **stdio newline-delimited JSON-RPC 2.0**:
   - `ping` → `pong`
   - `list_capabilities`
   - `start_run` (params: run config)
   - `cancel_run` (params: run id)
   - Notification: `run.event` (streaming output)
   - Notification: `run.complete`
   - Notification: `run.error`
3. Add `Shared/protocol/messages.schema.json` as the canonical schema.
4. Add Swift process manager that launches the Go binary and reads/writes its stdio pipes.
5. Stream mock run events into chat UI.
6. Record run events in SQLite.

Acceptance criteria:

- Swift app can start the Go helper.
- App can send ping and receive pong.
- App can start a mock run.
- Mock streamed events appear in UI.
- Helper process can be stopped cleanly.

## Phase 9: Provider API Integration

Goal: connect the runtime to real model providers.

Tasks:

1. Add OpenAI provider adapter in Go.
2. Add Anthropic provider adapter in Go.
3. Implement streaming text responses.
4. Pass selected chat context and messages to provider.
5. Store provider response metadata.
6. Add cancellation.
7. Add basic error handling in UI.

Acceptance criteria:

- User can send a chat message to OpenAI if configured.
- User can send a chat message to Anthropic if configured.
- Responses stream into the UI.
- Messages persist after restart.
- Failed requests show useful errors.

Deferred:

- Tool calling.
- Code editing.
- Shell execution.
- Provider model discovery.

## Phase 10: Tool Calling And File-Aware Agents

Goal: move from chat to useful coding-agent behavior.

Tasks:

1. Define tool interface:
   - read file
   - list files
   - apply patch
   - run command
   - git status
   - git diff
2. Add approval model.
3. Log every tool call.
4. Add UI for pending approvals.
5. Store tool calls and outputs.
6. Create diff artifacts after file modifications.

Acceptance criteria:

- Model can request file reads through controlled tools.
- App can approve or deny risky operations.
- File edits produce visible diffs.
- Tool history is visible in a run log.

## Phase 11: Artifacts And Run History

Goal: make outputs first-class.

Tasks:

1. Add artifacts screen per project.
2. Store diffs, generated files, command outputs, and reports.
3. Add run detail view.
4. Add before/after git state capture.
5. Add export/share flow for selected artifacts.

Acceptance criteria:

- Each agent run has a durable record.
- Diffs are saved as artifacts.
- User can revisit previous runs.
- User can identify which inputs produced which outputs.

## Phase 12: Workflow Layer

Goal: introduce reusable inference workflows after chat and run primitives are stable.

Tasks:

1. Define workflow schema.
2. Allow workflows to select:
   - project
   - documents
   - prompt
   - provider/model
   - output artifact type
3. Add manual workflow execution.
4. Add rerun support.
5. Add comparison of outputs across runs.

Acceptance criteria:

- User can save a simple workflow.
- User can rerun it.
- Outputs are tracked as artifacts.

## Suggested Initial Repository Layout

```text
current/                             <- repo root (github.com/RichardKnop/current)
  Current.xcodeproj                  <- Xcode project at root level
  Current/                           <- Swift app sources
    App/                             <- @main, AppDelegate if needed
    UI/                              <- SwiftUI views by feature
    Models/                          <- domain structs
    Stores/                          <- GRDB repositories
    Services/                        <- business logic
    Runtime/                         <- Go helper process manager and IPC
    Documents/                       <- document import/storage
    Settings/                        <- settings model and Keychain
    Git/                             <- git CLI wrapper
    Resources/                       <- assets, entitlements, Info.plist
  AgentRuntime/                      <- Go helper (Phase 8)
    go.mod
    cmd/
      agent-runtime/
    internal/
      protocol/
      providers/
      tools/
      runs/
  Shared/
    protocol/
      messages.schema.json           <- canonical JSON-RPC schema
  docs/
    architecture.md
    implementation-plan.md
  AGENTS.md
  CLAUDE.md
```

## Handoff Notes For Future Agents

Start with the lowest incomplete phase. Do not skip directly to provider APIs before the app shell, persistence, project CRUD, settings, and document library are working.

Prefer small, verifiable increments:

1. Build.
2. Run.
3. Verify persistence.
4. Commit.

When adding integrations, keep provider-specific behavior behind interfaces. The app should be a workbench for projects, runs, context, and artifacts, not a thin wrapper around any single vendor.

