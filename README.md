# Honcho Osaurus Plugin

Give your AI agent persistent, cross-session memory with the Honcho Osaurus plugin. Your agent will remember past conversations, learn from interactions, and maintain context across sessions — powered by [Honcho](https://honcho.dev).

## What It Does

The Honcho plugin enables your AI agent to:
- **Remember** conversations across sessions using semantic memory
- **Learn** facts and insights about you over time
- **Search** through past interactions to recall specific topics
- **Build context** automatically based on your working directory

Each project gets its own isolated memory space, so your agent remembers project-specific details without mixing contexts.

## Prerequisites

1. **Osaurus** — Download from [osaurus.ai](https://osaurus.ai)
2. **Honcho Account** — Sign up at [app.honcho.dev](https://app.honcho.dev) and get your API key

## Installation

### 1. Download the Plugin

Download the latest release: [dev.honcho.osaurus-1.0.0.zip](https://github.com/plastic-labs/honcho-osaurus-plugin/releases)

### 2. Install in Osaurus

1. Open **Osaurus Preferences** (⌘,)
2. Go to the **Plugins** tab
3. Click **Install Plugin**
4. Select the downloaded `dev.honcho.osaurus-1.0.0.zip` file
5. Restart Osaurus

### 3. Configure Your API Key

1. In Osaurus Preferences, find **Honcho** in the plugins list
2. Click **Configure**
3. Enter your **Honcho API Key** from [app.honcho.dev](https://app.honcho.dev)
4. Save settings

## Available Tools

The plugin provides 8 memory tools your agent can use:

### Core Memory Tools

#### `honcho_context`
Fetch user memory and session context — the primary tool for remembering you across sessions.

```json
{
  "search_query": "python preferences"  // optional: focus on a specific topic
}
```

**Permission:** Auto (runs automatically when needed)

---

#### `honcho_save_messages`
Persist conversation messages for long-term memory.

```json
{
  "messages": [
    {"role": "user", "content": "I prefer tabs over spaces"},
    {"role": "assistant", "content": "Noted! I'll use tabs in your projects."}
  ]
}
```

**Permission:** Ask (you'll be prompted before saving)

---

#### `honcho_save_conclusion`
Explicitly save a fact or insight about you.

```json
{
  "content": "User prefers functional programming patterns in JavaScript"
}
```

**Permission:** Ask (you'll be prompted before saving)

---

### Search & Retrieval Tools

#### `honcho_search`
Semantic search across all past conversations.

```json
{
  "query": "database setup",
  "limit": 5  // optional, default: 5
}
```

**Permission:** Auto

---

#### `honcho_profile`
Get your profile card containing key known facts.

```json
{}
```

**Permission:** Auto

---

#### `honcho_recall`
Ask Honcho a question using minimal reasoning (fast and cheap).

```json
{
  "query": "What's my preferred code style?"
}
```

**Permission:** Auto

---

#### `honcho_analyze`
Ask Honcho a question using deeper reasoning (more thorough but slower).

```json
{
  "query": "What patterns do I follow when architecting APIs?"
}
```

**Permission:** Auto

---

#### `honcho_session`
Get session-level context and conversation summary.

```json
{
  "include_summary": true  // optional, default: true
}
```

**Permission:** Auto

---

## How It Works

### Automatic Session Management

The plugin automatically creates memory sessions based on your **working directory**:

- `/Users/you/projects/my-app` → Session: `my-app`
- `/Users/you/work/client-site` → Session: `client-site`

Each session maintains its own conversation history while sharing your global user profile.

### Memory Architecture

```
Workspace: "osaurus"
├── User Profile (shared across all sessions)
│   └── Global facts and preferences about you
│
└── Sessions (one per project/directory)
    ├── Session: "my-app"
    │   └── Conversation history specific to this project
    │
    └── Session: "client-site"
        └── Conversation history specific to this project
```

### Peer Model

Each workspace has two participants:
- **owner** (you) — The human user
- **osaurus** (AI) — Your AI agent

The agent observes both its own messages and yours to build context, while you only observe your own messages (to prevent circular memory loops).

## Quick Start Example

1. **Start Osaurus** in a project directory
2. **Ask your agent** to remember something:
   ```
   Remember that I prefer using Tailwind CSS for styling
   ```
3. Your agent uses `honcho_save_conclusion` to store this fact

4. **In a later session**, ask:
   ```
   What CSS framework should I use?
   ```
5. Your agent uses `honcho_context` or `honcho_recall` and suggests Tailwind CSS

## Privacy & Data

- Your conversations are stored on Honcho's secure infrastructure
- Each project gets isolated memory — no cross-contamination
- You can view, edit, and delete your data at [app.honcho.dev](https://app.honcho.dev)
- API communication uses HTTPS encryption

## Troubleshooting

### Plugin Not Appearing

- Verify the zip file was installed correctly
- Restart Osaurus completely
- Check Osaurus Console for errors (View → Console)

### API Key Errors

- Verify your API key at [app.honcho.dev](https://app.honcho.dev)
- Ensure the key has no extra whitespace
- Check that your Honcho account is active

### Memory Not Persisting

- Confirm permission prompts are being approved
- Check your working directory is stable (session names derive from it)
- Verify network connectivity to `api.honcho.dev`

## Resources

- [Honcho Documentation](https://docs.honcho.dev)
- [Honcho Dashboard](https://app.honcho.dev)
- [Osaurus Documentation](https://osaurus.ai/docs)
- [Report Issues](https://github.com/plastic-labs/honcho-osaurus-plugin/issues)

## Development

See [CLAUDE.md](./CLAUDE.md) for development instructions, build commands, and architecture details.

## License

MIT License — See LICENSE file for details.

---

**Made with ❤️ by [Plastic Labs](https://plasticlabs.ai)**
