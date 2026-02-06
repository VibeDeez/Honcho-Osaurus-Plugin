# Honcho Osaurus Plugin Design

## Overview

**Plugin ID:** `dev.honcho.osaurus`
**Language:** Swift
**Target:** macOS Osaurus plugin (`.dylib` via C ABI)
**Purpose:** Persistent, cross-session memory for AI agents using Honcho as the backend.

A single Swift `.dylib` with zero external dependencies. Communicates with the Honcho v3 REST API via `URLSession`. Provides 8 tools covering context retrieval, message persistence, semantic search, user profiling, dialectic reasoning, and conclusion saving.

## Architecture

The plugin exports the `osaurus_plugin_entry` C ABI entry point and implements the five required functions: `init`, `destroy`, `get_manifest`, `invoke`, and `free_string`.

### File Structure

```
Package.swift
Sources/
├── Plugin.swift          # C ABI entry point + osr_plugin_api table
├── Manifest.swift        # JSON manifest (tools, secrets, metadata)
├── Router.swift          # invoke() dispatcher → routes tool IDs to handlers
├── HonchoClient.swift    # URLSession-based REST client for Honcho v3 API
├── Models.swift          # Codable structs for API requests/responses
├── SessionResolver.swift # Session naming from _context.working_directory
├── Tools/
│   ├── ContextTool.swift
│   ├── SaveMessagesTool.swift
│   ├── SearchTool.swift
│   ├── SaveConclusionTool.swift
│   ├── ProfileTool.swift
│   ├── RecallTool.swift
│   ├── AnalyzeTool.swift
│   └── SessionTool.swift
```

### Lifecycle

- `init()` creates a `PluginContext` holding the `HonchoClient` (lazily configured on first invocation when secrets are available).
- `destroy()` tears it down.
- `get_manifest()` returns the static JSON manifest.
- `invoke()` routes to the appropriate tool handler based on the capability `id`.
- `free_string()` frees plugin-allocated strings so the host can clean up.

## Secrets

One required secret, stored in macOS Keychain by Osaurus:

```json
"secrets": [
  {
    "id": "honcho_api_key",
    "label": "Honcho API Key",
    "description": "Get your API key from [Honcho](https://app.honcho.dev)",
    "required": true,
    "url": "https://app.honcho.dev"
  }
]
```

Injected into every tool invocation payload under `_secrets.honcho_api_key`.

## Permission Policies

- **Read-only tools** (`honcho_context`, `honcho_search`, `honcho_profile`, `honcho_session`, `honcho_recall`, `honcho_analyze`): `"auto"` -- safe to run without prompting.
- **Write tools** (`honcho_save_messages`, `honcho_save_conclusion`): `"ask"` -- user confirms before persisting data.

No macOS system permissions required. The `requirements` array for each tool is empty.

## Tools

### 1. `honcho_context`

Fetch user memory and session context. The primary "remember me" tool.

- **Params:** `search_query` (optional string) -- focus the context on a topic.
- **API:** `GET /sessions/{id}/context` with peer target/perspective params.
- **Returns:** Peer card, representation, and session summary combined.
- **Permission:** `auto`

### 2. `honcho_save_messages`

Persist conversation messages to Honcho.

- **Params:** `messages` (required array of `{role: "user"|"assistant", content: string}`).
- **API:** `POST /sessions/{id}/messages` with peer-tagged message inputs.
- **Returns:** Count of messages saved.
- **Permission:** `ask`

### 3. `honcho_search`

Semantic search across past conversations.

- **Params:** `query` (required string), `limit` (optional int, default 5).
- **API:** `GET /peers/{id}/representation` with search query.
- **Returns:** Matching content from past sessions.
- **Permission:** `auto`

### 4. `honcho_save_conclusion`

Explicitly save a fact about the user.

- **Params:** `content` (required string) -- the fact to save.
- **API:** `POST /peers/{id}/conclusions`
- **Returns:** Confirmation with conclusion ID.
- **Permission:** `ask`

### 5. `honcho_profile`

Get the user's peer card (key facts).

- **Params:** None (beyond `_secrets`/`_context`).
- **API:** `GET /peers/{id}/card`
- **Returns:** Bullet-point list of known user facts.
- **Permission:** `auto`

### 6. `honcho_recall`

Ask Honcho a question about the user with minimal reasoning.

- **Params:** `query` (required string).
- **API:** `POST /peers/{id}/chat` with `reasoning_level: "minimal"`.
- **Returns:** Honcho's answer about the user.
- **Permission:** `auto`

### 7. `honcho_analyze`

Deeper reasoning about the user.

- **Params:** `query` (required string).
- **API:** `POST /peers/{id}/chat` with `reasoning_level: "medium"`.
- **Returns:** More thorough analysis.
- **Permission:** `auto`

### 8. `honcho_session`

Get session-level context and summary.

- **Params:** `include_summary` (optional bool, default true).
- **API:** `GET /sessions/{id}/context` with summary flag.
- **Returns:** Session context and conversation summary.
- **Permission:** `auto`

## Data Flow

Every tool handler follows the same flow:

```
invoke(payload) →
  1. Decode JSON payload
  2. Extract _secrets.honcho_api_key and _context.working_directory
  3. Resolve session name (last path component of working_directory, or "default")
  4. Ensure peers exist (cached after first call):
     - "owner" peer (the human user)
     - "osaurus" peer (the AI agent)
  5. Ensure session exists (get-or-create by name)
  6. Execute the tool-specific API call
  7. Return JSON response string
```

### Peer Configuration

| Peer     | Identity  | observeMe | observeOthers |
|----------|-----------|-----------|---------------|
| owner    | The human | true      | false         |
| osaurus  | The AI    | true      | true          |

### Session Resolution

- If `_context.working_directory` is present: use the last path component (e.g., `/Users/alice/my-app` → `"my-app"`).
- If absent: use `"default"`.

### Default Configuration

- **API base URL:** `https://api.honcho.dev/v3`
- **Workspace ID:** `"osaurus"`

## Async Bridging

The C ABI `invoke()` is synchronous, but Honcho API calls are async. Bridge with a blocking semaphore:

```swift
func invokeSync(_ work: @Sendable () async throws -> String) -> String {
    let semaphore = DispatchSemaphore(value: 0)
    var result: String = ""
    Task {
        do {
            result = try await work()
        } catch {
            result = "{\"error\": \"\(error.localizedDescription)\"}"
        }
        semaphore.signal()
    }
    semaphore.wait()
    return result
}
```

## Error Handling

Every tool catches errors and returns a JSON error response -- never crashes the host.

- **Missing API key:** `{"error": "Honcho API key not configured. Get one at https://app.honcho.dev"}`
- **Missing working directory:** Falls back to session name `"default"` (no error).
- **Network failures:** Returns the HTTP status and Honcho error message.
- **Peer/session not found:** Creates them on the fly (get-or-create pattern).
- **Invalid JSON payload:** Returns a parse error with the tool ID for debugging.

No force-unwraps. No panics.

## Build and Packaging

```bash
# Build
swift build -c release --product HonchoPlugin

# Code sign
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: ..." .build/release/libHonchoPlugin.dylib

# Package
zip dev.honcho.osaurus-1.0.0.zip libHonchoPlugin.dylib

# Install locally
osaurus tools install dev.honcho.osaurus-1.0.0.zip
```

Installs to `~/Library/Application Support/com.dinoki.osaurus/Tools/dev.honcho.osaurus/1.0.0/`.
