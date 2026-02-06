import Foundation

enum Manifest {
    static let json: String = """
    {
      "plugin_id": "dev.honcho.osaurus",
      "version": "1.0.0",
      "description": "Persistent, cross-session memory for AI agents using Honcho",
      "secrets": [
        {
          "id": "honcho_api_key",
          "label": "Honcho API Key",
          "description": "Get your API key from [Honcho](https://app.honcho.dev)",
          "required": true,
          "url": "https://app.honcho.dev"
        }
      ],
      "capabilities": {
        "tools": [
          {
            "id": "honcho_context",
            "description": "Fetch user memory and session context. The primary tool for remembering the user across sessions.",
            "parameters": {
              "type": "object",
              "properties": {
                "search_query": {
                  "type": "string",
                  "description": "Optional topic to focus the context retrieval on"
                }
              }
            },
            "requirements": [],
            "permission_policy": "auto"
          },
          {
            "id": "honcho_save_messages",
            "description": "Persist conversation messages to Honcho for long-term memory.",
            "parameters": {
              "type": "object",
              "properties": {
                "messages": {
                  "type": "array",
                  "description": "Array of messages to save, each with role (user or assistant) and content",
                  "items": {
                    "type": "object",
                    "properties": {
                      "role": {
                        "type": "string",
                        "enum": ["user", "assistant"],
                        "description": "Who sent the message"
                      },
                      "content": {
                        "type": "string",
                        "description": "The message content"
                      }
                    },
                    "required": ["role", "content"]
                  }
                }
              },
              "required": ["messages"]
            },
            "requirements": [],
            "permission_policy": "ask"
          },
          {
            "id": "honcho_search",
            "description": "Semantic search across past conversations with the user.",
            "parameters": {
              "type": "object",
              "properties": {
                "query": {
                  "type": "string",
                  "description": "The search query"
                },
                "limit": {
                  "type": "integer",
                  "description": "Maximum number of results to return (default: 5)"
                }
              },
              "required": ["query"]
            },
            "requirements": [],
            "permission_policy": "auto"
          },
          {
            "id": "honcho_save_conclusion",
            "description": "Explicitly save a fact or insight about the user for future reference.",
            "parameters": {
              "type": "object",
              "properties": {
                "content": {
                  "type": "string",
                  "description": "The fact or insight to save about the user"
                }
              },
              "required": ["content"]
            },
            "requirements": [],
            "permission_policy": "ask"
          },
          {
            "id": "honcho_profile",
            "description": "Get the user's profile card containing key known facts about them.",
            "parameters": {
              "type": "object",
              "properties": {}
            },
            "requirements": [],
            "permission_policy": "auto"
          },
          {
            "id": "honcho_recall",
            "description": "Ask Honcho a question about the user using minimal reasoning. Fast and cheap.",
            "parameters": {
              "type": "object",
              "properties": {
                "query": {
                  "type": "string",
                  "description": "The question to ask about the user"
                }
              },
              "required": ["query"]
            },
            "requirements": [],
            "permission_policy": "auto"
          },
          {
            "id": "honcho_analyze",
            "description": "Ask Honcho a question about the user using deeper reasoning. More thorough but slower.",
            "parameters": {
              "type": "object",
              "properties": {
                "query": {
                  "type": "string",
                  "description": "The question to analyze about the user"
                }
              },
              "required": ["query"]
            },
            "requirements": [],
            "permission_policy": "auto"
          },
          {
            "id": "honcho_session",
            "description": "Get session-level context and conversation summary.",
            "parameters": {
              "type": "object",
              "properties": {
                "include_summary": {
                  "type": "boolean",
                  "description": "Whether to include the conversation summary (default: true)"
                }
              }
            },
            "requirements": [],
            "permission_policy": "auto"
          }
        ]
      }
    }
    """
}
