# Honcho Osaurus Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS Osaurus plugin (.dylib) that gives AI agents persistent memory via the Honcho v3 REST API.

**Architecture:** Single Swift dynamic library exporting the `osaurus_plugin_entry` C ABI. URLSession-based REST client talks to `https://api.honcho.dev/v3`. Eight tools exposed via a JSON manifest. Async Swift bridged to synchronous C ABI via DispatchSemaphore.

**Tech Stack:** Swift 6.2, SwiftPM (dynamic library product), Foundation/URLSession, no external dependencies.

---

### Task 1: SwiftPM Package Setup

**Files:**
- Create: `Package.swift`
- Create: `Sources/HonchoPlugin/Plugin.swift` (placeholder)

**Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HonchoPlugin",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "HonchoPlugin", type: .dynamic, targets: ["HonchoPlugin"])
    ],
    targets: [
        .target(name: "HonchoPlugin", path: "Sources/HonchoPlugin"),
        .testTarget(name: "HonchoPluginTests", dependencies: ["HonchoPlugin"], path: "Tests/HonchoPluginTests")
    ]
)
```

**Step 2: Create placeholder Plugin.swift**

```swift
import Foundation

// Placeholder — will be implemented in Task 3
```

**Step 3: Create placeholder test file**

Create `Tests/HonchoPluginTests/PlaceholderTest.swift`:

```swift
import XCTest
@testable import HonchoPlugin

final class PlaceholderTest: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }
}
```

**Step 4: Build to verify package resolves**

Run: `swift build`
Expected: Build succeeds with no errors.

**Step 5: Run tests to verify test target works**

Run: `swift test`
Expected: 1 test passes.

**Step 6: Commit**

```bash
git add Package.swift Sources/ Tests/
git commit -m "feat: initialize SwiftPM package for Honcho Osaurus plugin"
```

---

### Task 2: Codable Models

**Files:**
- Create: `Sources/HonchoPlugin/Models.swift`
- Create: `Tests/HonchoPluginTests/ModelsTests.swift`

These are the request/response structs for the Honcho v3 REST API.

**Step 1: Write the failing test**

Create `Tests/HonchoPluginTests/ModelsTests.swift`:

```swift
import XCTest
@testable import HonchoPlugin

final class ModelsTests: XCTestCase {

    func testPeerCreateEncodesToJSON() throws {
        let peer = PeerCreate(id: "owner", metadata: [:])
        let data = try JSONEncoder().encode(peer)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["id"] as? String, "owner")
    }

    func testPeerDecodeFromJSON() throws {
        let json = """
        {"id":"owner","workspace_id":"osaurus","created_at":"2025-01-01T00:00:00Z","metadata":{},"configuration":{}}
        """.data(using: .utf8)!
        let peer = try JSONDecoder().decode(Peer.self, from: json)
        XCTAssertEqual(peer.id, "owner")
        XCTAssertEqual(peer.workspaceId, "osaurus")
    }

    func testSessionCreateEncodesToJSON() throws {
        let session = SessionCreate(
            id: "my-project",
            metadata: [:],
            peers: ["owner": SessionPeerConfig(observeMe: true, observeOthers: false)]
        )
        let data = try JSONEncoder().encode(session)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["id"] as? String, "my-project")
        let peers = json["peers"] as? [String: Any]
        XCTAssertNotNil(peers?["owner"])
    }

    func testSessionDecodeFromJSON() throws {
        let json = """
        {"id":"my-project","is_active":true,"workspace_id":"osaurus","metadata":{},"configuration":{},"created_at":"2025-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let session = try JSONDecoder().decode(Session.self, from: json)
        XCTAssertEqual(session.id, "my-project")
        XCTAssertTrue(session.isActive)
    }

    func testMessageInputEncodesToJSON() throws {
        let msg = MessageInput(content: "Hello", peerId: "owner", metadata: nil)
        let data = try JSONEncoder().encode(msg)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["content"] as? String, "Hello")
        XCTAssertEqual(json["peer_id"] as? String, "owner")
    }

    func testMessageDecodeFromJSON() throws {
        let json = """
        {"id":"msg-1","content":"Hello","peer_id":"owner","session_id":"s1","metadata":{},"created_at":"2025-01-01T00:00:00Z","workspace_id":"osaurus","token_count":5}
        """.data(using: .utf8)!
        let msg = try JSONDecoder().decode(Message.self, from: json)
        XCTAssertEqual(msg.id, "msg-1")
        XCTAssertEqual(msg.content, "Hello")
        XCTAssertEqual(msg.tokenCount, 5)
    }

    func testSessionContextDecodeFromJSON() throws {
        let json = """
        {
          "id": "ctx-1",
          "messages": [],
          "summary": {"content":"summary text","message_id":"m1","summary_type":"short","created_at":"2025-01-01T00:00:00Z","token_count":10},
          "peer_representation": "Knows Swift",
          "peer_card": ["Likes coding", "Uses macOS"]
        }
        """.data(using: .utf8)!
        let ctx = try JSONDecoder().decode(SessionContext.self, from: json)
        XCTAssertEqual(ctx.peerRepresentation, "Knows Swift")
        XCTAssertEqual(ctx.peerCard?.count, 2)
        XCTAssertEqual(ctx.summary?.content, "summary text")
    }

    func testConclusionCreateEncodesToJSON() throws {
        let c = ConclusionCreate(content: "User likes Swift", observerId: "osaurus", observedId: "owner", sessionId: "s1")
        let data = try JSONEncoder().encode(c)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["content"] as? String, "User likes Swift")
        XCTAssertEqual(json["observer_id"] as? String, "osaurus")
        XCTAssertEqual(json["observed_id"] as? String, "owner")
        XCTAssertEqual(json["session_id"] as? String, "s1")
    }

    func testConclusionDecodeFromJSON() throws {
        let json = """
        {"id":"c-1","content":"User likes Swift","observer_id":"osaurus","observed_id":"owner","session_id":"s1","created_at":"2025-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let c = try JSONDecoder().decode(Conclusion.self, from: json)
        XCTAssertEqual(c.id, "c-1")
        XCTAssertEqual(c.content, "User likes Swift")
    }

    func testChatRequestEncodesToJSON() throws {
        let req = ChatRequest(query: "What does the user like?", sessionId: "s1", target: "owner", reasoningLevel: "minimal")
        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["query"] as? String, "What does the user like?")
        XCTAssertEqual(json["reasoning_level"] as? String, "minimal")
    }

    func testChatResponseDecodeFromJSON() throws {
        let json = """
        {"content":"The user enjoys programming in Swift."}
        """.data(using: .utf8)!
        let resp = try JSONDecoder().decode(ChatResponse.self, from: json)
        XCTAssertEqual(resp.content, "The user enjoys programming in Swift.")
    }

    func testRepresentationRequestEncodesToJSON() throws {
        let req = RepresentationRequest(searchQuery: "preferences", searchTopK: 5)
        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["search_query"] as? String, "preferences")
        XCTAssertEqual(json["search_top_k"] as? Int, 5)
    }

    func testRepresentationResponseDecodeFromJSON() throws {
        let json = """
        {"representation":"User is a Swift developer who prefers clean code."}
        """.data(using: .utf8)!
        let resp = try JSONDecoder().decode(RepresentationResponse.self, from: json)
        XCTAssertEqual(resp.representation, "User is a Swift developer who prefers clean code.")
    }

    func testWorkspaceCreateEncodesToJSON() throws {
        let ws = WorkspaceCreate(id: "osaurus", metadata: [:])
        let data = try JSONEncoder().encode(ws)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["id"] as? String, "osaurus")
    }

    func testSessionSummariesDecodeFromJSON() throws {
        let json = """
        {
          "id": "s1",
          "short_summary": {"content":"Short","message_id":"m1","summary_type":"short","created_at":"2025-01-01T00:00:00Z","token_count":5},
          "long_summary": null
        }
        """.data(using: .utf8)!
        let s = try JSONDecoder().decode(SessionSummaries.self, from: json)
        XCTAssertEqual(s.shortSummary?.content, "Short")
        XCTAssertNil(s.longSummary)
    }

    func testPeerCardResponseDecodeFromJSON() throws {
        let json = """
        {"peer_card": ["Fact 1", "Fact 2"]}
        """.data(using: .utf8)!
        let resp = try JSONDecoder().decode(PeerCardResponse.self, from: json)
        XCTAssertEqual(resp.peerCard?.count, 2)
    }

    func testSearchRequestEncodesToJSON() throws {
        let req = SearchRequest(query: "swift programming", limit: 5)
        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["query"] as? String, "swift programming")
        XCTAssertEqual(json["limit"] as? Int, 5)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter ModelsTests`
Expected: Compilation fails — types not defined yet.

**Step 3: Write the implementation**

Create `Sources/HonchoPlugin/Models.swift`:

```swift
import Foundation

// MARK: - Workspace

struct WorkspaceCreate: Encodable {
    let id: String
    let metadata: [String: String]
}

struct Workspace: Decodable {
    let id: String
    let createdAt: String
    let metadata: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case metadata
    }
}

// MARK: - Peer

struct PeerCreate: Encodable {
    let id: String
    let metadata: [String: String]
}

struct Peer: Decodable {
    let id: String
    let workspaceId: String
    let createdAt: String
    let metadata: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case createdAt = "created_at"
        case metadata
    }
}

struct PeerCardResponse: Decodable {
    let peerCard: [String]?

    enum CodingKeys: String, CodingKey {
        case peerCard = "peer_card"
    }
}

// MARK: - Session

struct SessionPeerConfig: Codable {
    let observeMe: Bool?
    let observeOthers: Bool?

    enum CodingKeys: String, CodingKey {
        case observeMe = "observe_me"
        case observeOthers = "observe_others"
    }
}

struct SessionCreate: Encodable {
    let id: String
    let metadata: [String: String]
    let peers: [String: SessionPeerConfig]?
}

struct Session: Decodable {
    let id: String
    let isActive: Bool
    let workspaceId: String
    let metadata: [String: AnyCodable]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case isActive = "is_active"
        case workspaceId = "workspace_id"
        case metadata
        case createdAt = "created_at"
    }
}

struct SessionSummaries: Decodable {
    let id: String
    let shortSummary: Summary?
    let longSummary: Summary?

    enum CodingKeys: String, CodingKey {
        case id
        case shortSummary = "short_summary"
        case longSummary = "long_summary"
    }
}

// MARK: - Session Context

struct Summary: Decodable {
    let content: String
    let messageId: String
    let summaryType: String
    let createdAt: String
    let tokenCount: Int

    enum CodingKeys: String, CodingKey {
        case content
        case messageId = "message_id"
        case summaryType = "summary_type"
        case createdAt = "created_at"
        case tokenCount = "token_count"
    }
}

struct SessionContext: Decodable {
    let id: String
    let messages: [Message]
    let summary: Summary?
    let peerRepresentation: String?
    let peerCard: [String]?

    enum CodingKeys: String, CodingKey {
        case id, messages, summary
        case peerRepresentation = "peer_representation"
        case peerCard = "peer_card"
    }
}

// MARK: - Message

struct MessageInput: Encodable {
    let content: String
    let peerId: String
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case content
        case peerId = "peer_id"
        case metadata
    }
}

struct MessageBatchCreate: Encodable {
    let messages: [MessageInput]
}

struct Message: Decodable {
    let id: String
    let content: String
    let peerId: String
    let sessionId: String
    let metadata: [String: AnyCodable]
    let createdAt: String
    let workspaceId: String
    let tokenCount: Int

    enum CodingKeys: String, CodingKey {
        case id, content, metadata
        case peerId = "peer_id"
        case sessionId = "session_id"
        case createdAt = "created_at"
        case workspaceId = "workspace_id"
        case tokenCount = "token_count"
    }
}

// MARK: - Conclusion

struct ConclusionCreate: Encodable {
    let content: String
    let observerId: String
    let observedId: String
    let sessionId: String?

    enum CodingKeys: String, CodingKey {
        case content
        case observerId = "observer_id"
        case observedId = "observed_id"
        case sessionId = "session_id"
    }
}

struct ConclusionBatchCreate: Encodable {
    let conclusions: [ConclusionCreate]
}

struct Conclusion: Decodable {
    let id: String
    let content: String
    let observerId: String
    let observedId: String
    let sessionId: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, content
        case observerId = "observer_id"
        case observedId = "observed_id"
        case sessionId = "session_id"
        case createdAt = "created_at"
    }
}

// MARK: - Chat

struct ChatRequest: Encodable {
    let query: String
    let sessionId: String?
    let target: String?
    let reasoningLevel: String?

    enum CodingKeys: String, CodingKey {
        case query
        case sessionId = "session_id"
        case target
        case reasoningLevel = "reasoning_level"
    }
}

struct ChatResponse: Decodable {
    let content: String?
}

// MARK: - Representation

struct RepresentationRequest: Encodable {
    let sessionId: String?
    let target: String?
    let searchQuery: String?
    let searchTopK: Int?
    let searchMaxDistance: Double?
    let includeMostFrequent: Bool?
    let maxConclusions: Int?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case target
        case searchQuery = "search_query"
        case searchTopK = "search_top_k"
        case searchMaxDistance = "search_max_distance"
        case includeMostFrequent = "include_most_frequent"
        case maxConclusions = "max_conclusions"
    }

    init(sessionId: String? = nil, target: String? = nil, searchQuery: String? = nil, searchTopK: Int? = nil, searchMaxDistance: Double? = nil, includeMostFrequent: Bool? = nil, maxConclusions: Int? = nil) {
        self.sessionId = sessionId
        self.target = target
        self.searchQuery = searchQuery
        self.searchTopK = searchTopK
        self.searchMaxDistance = searchMaxDistance
        self.includeMostFrequent = includeMostFrequent
        self.maxConclusions = maxConclusions
    }
}

struct RepresentationResponse: Decodable {
    let representation: String
}

// MARK: - Search

struct SearchRequest: Encodable {
    let query: String
    let limit: Int?
}

// MARK: - Invocation Payload Helpers

struct InvocationPayload: Decodable {
    let secrets: [String: String]?
    let context: PayloadContext?

    enum CodingKeys: String, CodingKey {
        case secrets = "_secrets"
        case context = "_context"
    }
}

struct PayloadContext: Decodable {
    let workingDirectory: String?

    enum CodingKeys: String, CodingKey {
        case workingDirectory = "working_directory"
    }
}

// MARK: - AnyCodable (minimal, decode-only)

struct AnyCodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter ModelsTests`
Expected: All tests pass.

**Step 5: Commit**

```bash
git add Sources/HonchoPlugin/Models.swift Tests/HonchoPluginTests/ModelsTests.swift
git commit -m "feat: add Codable models for Honcho v3 API"
```

---

### Task 3: Session Resolver

**Files:**
- Create: `Sources/HonchoPlugin/SessionResolver.swift`
- Create: `Tests/HonchoPluginTests/SessionResolverTests.swift`

**Step 1: Write the failing test**

Create `Tests/HonchoPluginTests/SessionResolverTests.swift`:

```swift
import XCTest
@testable import HonchoPlugin

final class SessionResolverTests: XCTestCase {

    func testResolvesLastPathComponent() {
        let name = SessionResolver.resolve(workingDirectory: "/Users/alice/projects/my-app")
        XCTAssertEqual(name, "my-app")
    }

    func testResolvesWithTrailingSlash() {
        let name = SessionResolver.resolve(workingDirectory: "/Users/alice/projects/my-app/")
        XCTAssertEqual(name, "my-app")
    }

    func testFallsBackToDefaultWhenNil() {
        let name = SessionResolver.resolve(workingDirectory: nil)
        XCTAssertEqual(name, "default")
    }

    func testFallsBackToDefaultWhenEmpty() {
        let name = SessionResolver.resolve(workingDirectory: "")
        XCTAssertEqual(name, "default")
    }

    func testFallsBackToDefaultWhenRootSlash() {
        let name = SessionResolver.resolve(workingDirectory: "/")
        XCTAssertEqual(name, "default")
    }

    func testSanitizesSpecialCharacters() {
        let name = SessionResolver.resolve(workingDirectory: "/Users/alice/My Project (v2)")
        XCTAssertEqual(name, "My-Project--v2-")
    }

    func testPreservesHyphensAndUnderscores() {
        let name = SessionResolver.resolve(workingDirectory: "/Users/alice/my_cool-project")
        XCTAssertEqual(name, "my_cool-project")
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter SessionResolverTests`
Expected: Compilation fails — `SessionResolver` not defined.

**Step 3: Write the implementation**

Create `Sources/HonchoPlugin/SessionResolver.swift`:

```swift
import Foundation

enum SessionResolver {
    /// Resolves a session name from the working directory path.
    /// Uses the last path component, sanitized to alphanumeric + hyphens + underscores.
    /// Falls back to "default" if the path is nil, empty, or root.
    static func resolve(workingDirectory: String?) -> String {
        guard let dir = workingDirectory, !dir.isEmpty else {
            return "default"
        }

        let url = URL(fileURLWithPath: dir)
        let lastComponent = url.lastPathComponent

        if lastComponent == "/" || lastComponent.isEmpty {
            return "default"
        }

        // Honcho session IDs: alphanumeric, hyphens, underscores, 1-100 chars
        let sanitized = lastComponent.map { c -> Character in
            if c.isLetter || c.isNumber || c == "-" || c == "_" {
                return c
            }
            return "-"
        }

        let result = String(sanitized)
        if result.isEmpty {
            return "default"
        }

        // Truncate to 100 characters (Honcho limit)
        return String(result.prefix(100))
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter SessionResolverTests`
Expected: All tests pass.

**Step 5: Commit**

```bash
git add Sources/HonchoPlugin/SessionResolver.swift Tests/HonchoPluginTests/SessionResolverTests.swift
git commit -m "feat: add session resolver for working directory to session name"
```

---

### Task 4: JSON Manifest

**Files:**
- Create: `Sources/HonchoPlugin/Manifest.swift`
- Create: `Tests/HonchoPluginTests/ManifestTests.swift`

**Step 1: Write the failing test**

Create `Tests/HonchoPluginTests/ManifestTests.swift`:

```swift
import XCTest
@testable import HonchoPlugin

final class ManifestTests: XCTestCase {

    func testManifestIsValidJSON() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(obj["plugin_id"] as? String, "dev.honcho.osaurus")
        XCTAssertEqual(obj["version"] as? String, "1.0.0")
    }

    func testManifestHasEightTools() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let capabilities = obj["capabilities"] as! [String: Any]
        let tools = capabilities["tools"] as! [[String: Any]]
        XCTAssertEqual(tools.count, 8)
    }

    func testManifestHasOneSecret() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let secrets = obj["secrets"] as! [[String: Any]]
        XCTAssertEqual(secrets.count, 1)
        XCTAssertEqual(secrets[0]["id"] as? String, "honcho_api_key")
        XCTAssertEqual(secrets[0]["required"] as? Bool, true)
    }

    func testManifestToolIds() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let capabilities = obj["capabilities"] as! [String: Any]
        let tools = capabilities["tools"] as! [[String: Any]]
        let ids = tools.map { $0["id"] as! String }.sorted()
        XCTAssertEqual(ids, [
            "honcho_analyze",
            "honcho_context",
            "honcho_profile",
            "honcho_recall",
            "honcho_save_conclusion",
            "honcho_save_messages",
            "honcho_search",
            "honcho_session"
        ])
    }

    func testWriteToolsHaveAskPermission() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let capabilities = obj["capabilities"] as! [String: Any]
        let tools = capabilities["tools"] as! [[String: Any]]
        let writeTools = tools.filter { ["honcho_save_messages", "honcho_save_conclusion"].contains($0["id"] as? String) }
        for tool in writeTools {
            XCTAssertEqual(tool["permission_policy"] as? String, "ask")
        }
    }

    func testReadToolsHaveAutoPermission() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let capabilities = obj["capabilities"] as! [String: Any]
        let tools = capabilities["tools"] as! [[String: Any]]
        let readToolIds = ["honcho_context", "honcho_search", "honcho_profile", "honcho_recall", "honcho_analyze", "honcho_session"]
        let readTools = tools.filter { readToolIds.contains($0["id"] as? String ?? "") }
        XCTAssertEqual(readTools.count, 6)
        for tool in readTools {
            XCTAssertEqual(tool["permission_policy"] as? String, "auto")
        }
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter ManifestTests`
Expected: Compilation fails — `Manifest` not defined.

**Step 3: Write the implementation**

Create `Sources/HonchoPlugin/Manifest.swift`:

```swift
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
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter ManifestTests`
Expected: All tests pass.

**Step 5: Commit**

```bash
git add Sources/HonchoPlugin/Manifest.swift Tests/HonchoPluginTests/ManifestTests.swift
git commit -m "feat: add JSON manifest with 8 tools and secrets"
```

---

### Task 5: Honcho REST Client

**Files:**
- Create: `Sources/HonchoPlugin/HonchoClient.swift`
- Create: `Tests/HonchoPluginTests/HonchoClientTests.swift`

This is the core HTTP client. It wraps URLSession and provides typed methods for each Honcho v3 endpoint.

**Step 1: Write the failing test**

Create `Tests/HonchoPluginTests/HonchoClientTests.swift`:

```swift
import XCTest
@testable import HonchoPlugin

final class HonchoClientTests: XCTestCase {

    func testBuildURLConstructsCorrectPath() {
        let client = HonchoClient(apiKey: "hch-test", workspaceId: "osaurus")
        let url = client.buildURL(path: "/peers")
        XCTAssertEqual(url?.absoluteString, "https://api.honcho.dev/v3/workspaces/osaurus/peers")
    }

    func testBuildURLWithQueryParams() {
        let client = HonchoClient(apiKey: "hch-test", workspaceId: "osaurus")
        let url = client.buildURL(path: "/sessions/s1/context", queryItems: [
            URLQueryItem(name: "summary", value: "true"),
            URLQueryItem(name: "peer_target", value: "owner")
        ])
        let urlString = url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("summary=true"))
        XCTAssertTrue(urlString.contains("peer_target=owner"))
    }

    func testBuildRequestSetsAuthHeader() {
        let client = HonchoClient(apiKey: "hch-test-key", workspaceId: "osaurus")
        let url = URL(string: "https://api.honcho.dev/v3/workspaces/osaurus/peers")!
        let request = client.buildRequest(url: url, method: "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer hch-test-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testBuildRequestSetsMethod() {
        let client = HonchoClient(apiKey: "hch-test", workspaceId: "osaurus")
        let url = URL(string: "https://api.honcho.dev/v3/workspaces/osaurus/peers")!
        let getReq = client.buildRequest(url: url, method: "GET")
        XCTAssertEqual(getReq.httpMethod, "GET")
        let postReq = client.buildRequest(url: url, method: "POST")
        XCTAssertEqual(postReq.httpMethod, "POST")
    }

    func testCustomBaseURL() {
        let client = HonchoClient(apiKey: "hch-test", workspaceId: "osaurus", baseURL: "http://localhost:8000/v3")
        let url = client.buildURL(path: "/peers")
        XCTAssertEqual(url?.absoluteString, "http://localhost:8000/v3/workspaces/osaurus/peers")
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter HonchoClientTests`
Expected: Compilation fails — `HonchoClient` not defined.

**Step 3: Write the implementation**

Create `Sources/HonchoPlugin/HonchoClient.swift`:

```swift
import Foundation

final class HonchoClient: @unchecked Sendable {
    let apiKey: String
    let workspaceId: String
    let baseURL: String

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(apiKey: String, workspaceId: String, baseURL: String = "https://api.honcho.dev/v3") {
        self.apiKey = apiKey
        self.workspaceId = workspaceId
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - URL and Request Building (internal for testing)

    func buildURL(path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        let urlString = "\(baseURL)/workspaces/\(workspaceId)\(path)"
        guard var components = URLComponents(string: urlString) else { return nil }
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }

    func buildRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    // MARK: - Generic HTTP

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HonchoError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw HonchoError.httpError(statusCode: httpResponse.statusCode, body: body)
        }
        return try decoder.decode(T.self, from: data)
    }

    private func executeNoContent(_ request: URLRequest) async throws {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HonchoError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw HonchoError.httpError(statusCode: httpResponse.statusCode, body: body)
        }
    }

    // MARK: - Workspace

    func getOrCreateWorkspace() async throws -> Workspace {
        // This endpoint is POST /v3/workspaces (no workspace_id in path)
        let urlString = "\(baseURL)/workspaces"
        guard let url = URL(string: urlString) else { throw HonchoError.invalidURL }
        let body = try encoder.encode(WorkspaceCreate(id: workspaceId, metadata: [:]))
        let request = buildRequest(url: url, method: "POST", body: body)
        return try await execute(request)
    }

    // MARK: - Peers

    func getOrCreatePeer(id: String) async throws -> Peer {
        guard let url = buildURL(path: "/peers") else { throw HonchoError.invalidURL }
        let body = try encoder.encode(PeerCreate(id: id, metadata: [:]))
        let request = buildRequest(url: url, method: "POST", body: body)
        return try await execute(request)
    }

    func getPeerCard(peerId: String, target: String? = nil) async throws -> PeerCardResponse {
        var queryItems: [URLQueryItem] = []
        if let target { queryItems.append(URLQueryItem(name: "target", value: target)) }
        guard let url = buildURL(path: "/peers/\(peerId)/card", queryItems: queryItems.isEmpty ? nil : queryItems) else {
            throw HonchoError.invalidURL
        }
        let request = buildRequest(url: url, method: "GET")
        return try await execute(request)
    }

    func getRepresentation(peerId: String, body representationRequest: RepresentationRequest) async throws -> RepresentationResponse {
        guard let url = buildURL(path: "/peers/\(peerId)/representation") else { throw HonchoError.invalidURL }
        let body = try encoder.encode(representationRequest)
        let request = buildRequest(url: url, method: "POST", body: body)
        return try await execute(request)
    }

    func chat(peerId: String, body chatRequest: ChatRequest) async throws -> ChatResponse {
        guard let url = buildURL(path: "/peers/\(peerId)/chat") else { throw HonchoError.invalidURL }
        let body = try encoder.encode(chatRequest)
        let request = buildRequest(url: url, method: "POST", body: body)
        return try await execute(request)
    }

    // MARK: - Sessions

    func getOrCreateSession(id: String, peers: [String: SessionPeerConfig]? = nil) async throws -> Session {
        guard let url = buildURL(path: "/sessions") else { throw HonchoError.invalidURL }
        let body = try encoder.encode(SessionCreate(id: id, metadata: [:], peers: peers))
        let request = buildRequest(url: url, method: "POST", body: body)
        return try await execute(request)
    }

    func addPeersToSession(sessionId: String, peers: [String: SessionPeerConfig]) async throws -> Session {
        guard let url = buildURL(path: "/sessions/\(sessionId)/peers") else { throw HonchoError.invalidURL }
        let body = try encoder.encode(peers)
        let request = buildRequest(url: url, method: "POST", body: body)
        return try await execute(request)
    }

    func getSessionContext(sessionId: String, searchQuery: String? = nil, summary: Bool = true, peerTarget: String? = nil, peerPerspective: String? = nil) async throws -> SessionContext {
        var queryItems: [URLQueryItem] = []
        if let searchQuery { queryItems.append(URLQueryItem(name: "search_query", value: searchQuery)) }
        queryItems.append(URLQueryItem(name: "summary", value: summary ? "true" : "false"))
        if let peerTarget { queryItems.append(URLQueryItem(name: "peer_target", value: peerTarget)) }
        if let peerPerspective { queryItems.append(URLQueryItem(name: "peer_perspective", value: peerPerspective)) }
        guard let url = buildURL(path: "/sessions/\(sessionId)/context", queryItems: queryItems) else {
            throw HonchoError.invalidURL
        }
        let request = buildRequest(url: url, method: "GET")
        return try await execute(request)
    }

    func getSessionSummaries(sessionId: String) async throws -> SessionSummaries {
        guard let url = buildURL(path: "/sessions/\(sessionId)/summaries") else { throw HonchoError.invalidURL }
        let request = buildRequest(url: url, method: "GET")
        return try await execute(request)
    }

    func searchSession(sessionId: String, query: String, limit: Int = 5) async throws -> [Message] {
        guard let url = buildURL(path: "/sessions/\(sessionId)/search") else { throw HonchoError.invalidURL }
        let body = try encoder.encode(SearchRequest(query: query, limit: limit))
        let request = buildRequest(url: url, method: "POST", body: body)
        return try await execute(request)
    }

    // MARK: - Messages

    func createMessages(sessionId: String, messages: [MessageInput]) async throws -> [Message] {
        guard let url = buildURL(path: "/sessions/\(sessionId)/messages") else { throw HonchoError.invalidURL }
        let body = try encoder.encode(MessageBatchCreate(messages: messages))
        let request = buildRequest(url: url, method: "POST", body: body)
        return try await execute(request)
    }

    // MARK: - Conclusions

    func createConclusion(content: String, observerId: String, observedId: String, sessionId: String?) async throws -> [Conclusion] {
        guard let url = buildURL(path: "/conclusions") else { throw HonchoError.invalidURL }
        let conclusion = ConclusionCreate(content: content, observerId: observerId, observedId: observedId, sessionId: sessionId)
        let body = try encoder.encode(ConclusionBatchCreate(conclusions: [conclusion]))
        let request = buildRequest(url: url, method: "POST", body: body)
        return try await execute(request)
    }
}

// MARK: - Errors

enum HonchoError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Failed to construct Honcho API URL"
        case .invalidResponse:
            return "Invalid response from Honcho API"
        case .httpError(let code, let body):
            return "Honcho API error \(code): \(body)"
        case .missingAPIKey:
            return "Honcho API key not configured. Get one at https://app.honcho.dev"
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter HonchoClientTests`
Expected: All tests pass.

**Step 5: Commit**

```bash
git add Sources/HonchoPlugin/HonchoClient.swift Tests/HonchoPluginTests/HonchoClientTests.swift
git commit -m "feat: add Honcho REST client with URLSession"
```

---

### Task 6: Plugin Context and Async Bridge

**Files:**
- Create: `Sources/HonchoPlugin/PluginContext.swift`
- Create: `Tests/HonchoPluginTests/PluginContextTests.swift`

The PluginContext holds the cached HonchoClient and peer/session state. It also provides the sync-to-async bridge.

**Step 1: Write the failing test**

Create `Tests/HonchoPluginTests/PluginContextTests.swift`:

```swift
import XCTest
@testable import HonchoPlugin

final class PluginContextTests: XCTestCase {

    func testInvokeSyncReturnsResult() {
        let result = PluginContext.invokeSync {
            return "hello"
        }
        XCTAssertEqual(result, "hello")
    }

    func testInvokeSyncReturnsErrorJSON() {
        let result = PluginContext.invokeSync {
            throw HonchoError.missingAPIKey
        }
        XCTAssertTrue(result.contains("error"))
        XCTAssertTrue(result.contains("api.honcho.dev") || result.contains("app.honcho.dev"))
    }

    func testExtractAPIKeyFromPayload() throws {
        let json = """
        {"_secrets": {"honcho_api_key": "hch-test123"}, "_context": {"working_directory": "/tmp/test"}}
        """
        let payload = try JSONDecoder().decode(InvocationPayload.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(payload.secrets?["honcho_api_key"], "hch-test123")
        XCTAssertEqual(payload.context?.workingDirectory, "/tmp/test")
    }

    func testExtractAPIKeyMissingReturnsNil() throws {
        let json = """
        {"_secrets": {}, "_context": {"working_directory": "/tmp/test"}}
        """
        let payload = try JSONDecoder().decode(InvocationPayload.self, from: json.data(using: .utf8)!)
        XCTAssertNil(payload.secrets?["honcho_api_key"])
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter PluginContextTests`
Expected: Compilation fails — `PluginContext` not defined.

**Step 3: Write the implementation**

Create `Sources/HonchoPlugin/PluginContext.swift`:

```swift
import Foundation

final class PluginContext: @unchecked Sendable {
    private let defaultWorkspaceId = "osaurus"
    private let ownerPeerId = "owner"
    private let agentPeerId = "osaurus"

    // Cached state
    private var cachedClient: HonchoClient?
    private var cachedApiKey: String?
    private var workspaceInitialized = false
    private var peersInitialized = false

    /// Bridge synchronous C ABI invoke() to async Swift.
    static func invokeSync(_ work: @Sendable @escaping () async throws -> String) -> String {
        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var result = ""
        Task {
            do {
                result = try await work()
            } catch {
                let escaped = error.localizedDescription
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                result = "{\"error\": \"\(escaped)\"}"
            }
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    /// Get or create a HonchoClient for the given API key.
    /// Re-uses the cached client if the key hasn't changed.
    func client(apiKey: String) -> HonchoClient {
        if let cached = cachedClient, cachedApiKey == apiKey {
            return cached
        }
        let c = HonchoClient(apiKey: apiKey, workspaceId: defaultWorkspaceId)
        cachedClient = c
        cachedApiKey = apiKey
        return c
    }

    /// Ensure workspace and peers exist. Called before each tool invocation.
    /// Idempotent — only makes API calls on first invocation.
    func ensureInitialized(client: HonchoClient) async throws {
        if !workspaceInitialized {
            _ = try await client.getOrCreateWorkspace()
            workspaceInitialized = true
        }
        if !peersInitialized {
            _ = try await client.getOrCreatePeer(id: ownerPeerId)
            _ = try await client.getOrCreatePeer(id: agentPeerId)
            peersInitialized = true
        }
    }

    /// Ensure session exists with peer configuration.
    func ensureSession(client: HonchoClient, sessionName: String) async throws -> Session {
        let peers: [String: SessionPeerConfig] = [
            ownerPeerId: SessionPeerConfig(observeMe: true, observeOthers: false),
            agentPeerId: SessionPeerConfig(observeMe: true, observeOthers: true)
        ]
        return try await client.getOrCreateSession(id: sessionName, peers: peers)
    }

    /// Parse the payload and return (apiKey, sessionName, client).
    func parsePayload(_ payloadJSON: String) throws -> (apiKey: String, sessionName: String, client: HonchoClient) {
        guard let data = payloadJSON.data(using: .utf8) else {
            throw HonchoError.invalidResponse
        }
        let payload = try JSONDecoder().decode(InvocationPayload.self, from: data)
        guard let apiKey = payload.secrets?["honcho_api_key"], !apiKey.isEmpty else {
            throw HonchoError.missingAPIKey
        }
        let sessionName = SessionResolver.resolve(workingDirectory: payload.context?.workingDirectory)
        let c = client(apiKey: apiKey)
        return (apiKey, sessionName, c)
    }

    var ownerPeer: String { ownerPeerId }
    var agentPeer: String { agentPeerId }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter PluginContextTests`
Expected: All tests pass.

**Step 5: Commit**

```bash
git add Sources/HonchoPlugin/PluginContext.swift Tests/HonchoPluginTests/PluginContextTests.swift
git commit -m "feat: add plugin context with async bridge and payload parsing"
```

---

### Task 7: Tool Handlers

**Files:**
- Create: `Sources/HonchoPlugin/Tools/ContextTool.swift`
- Create: `Sources/HonchoPlugin/Tools/SaveMessagesTool.swift`
- Create: `Sources/HonchoPlugin/Tools/SearchTool.swift`
- Create: `Sources/HonchoPlugin/Tools/SaveConclusionTool.swift`
- Create: `Sources/HonchoPlugin/Tools/ProfileTool.swift`
- Create: `Sources/HonchoPlugin/Tools/RecallTool.swift`
- Create: `Sources/HonchoPlugin/Tools/AnalyzeTool.swift`
- Create: `Sources/HonchoPlugin/Tools/SessionTool.swift`

Each tool follows the same pattern: parse payload → get client + session → call Honcho API → return JSON string.

**Step 1: Create all 8 tool handlers**

Create `Sources/HonchoPlugin/Tools/ContextTool.swift`:

```swift
import Foundation

enum ContextTool {
    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        // Parse optional search_query from payload
        let searchQuery: String? = {
            guard let data = payload.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            return json["search_query"] as? String
        }()

        let context = try await client.getSessionContext(
            sessionId: session.id,
            searchQuery: searchQuery,
            summary: true,
            peerTarget: ctx.ownerPeer,
            peerPerspective: ctx.agentPeer
        )

        var parts: [String] = []
        if let card = context.peerCard, !card.isEmpty {
            parts.append("## User Facts\n" + card.map { "- \($0)" }.joined(separator: "\n"))
        }
        if let rep = context.peerRepresentation, !rep.isEmpty {
            parts.append("## User Context\n\(rep)")
        }
        if let summary = context.summary {
            parts.append("## Session Summary\n\(summary.content)")
        }

        let result = parts.isEmpty ? "No memory context available yet." : parts.joined(separator: "\n\n")
        return encodeResult(result)
    }
}
```

Create `Sources/HonchoPlugin/Tools/SaveMessagesTool.swift`:

```swift
import Foundation

enum SaveMessagesTool {
    struct SaveMessagesParams: Decodable {
        let messages: [MessageParam]

        struct MessageParam: Decodable {
            let role: String
            let content: String
        }
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        guard let data = payload.data(using: .utf8) else { throw HonchoError.invalidResponse }
        let params = try JSONDecoder().decode(SaveMessagesParams.self, from: data)

        let inputs = params.messages.map { msg in
            let peerId = msg.role == "user" ? ctx.ownerPeer : ctx.agentPeer
            return MessageInput(content: msg.content, peerId: peerId, metadata: nil)
        }

        let saved = try await client.createMessages(sessionId: session.id, messages: inputs)
        return encodeResult("Saved \(saved.count) message(s) to session '\(sessionName)'.")
    }
}
```

Create `Sources/HonchoPlugin/Tools/SearchTool.swift`:

```swift
import Foundation

enum SearchTool {
    struct SearchParams: Decodable {
        let query: String
        let limit: Int?
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        guard let data = payload.data(using: .utf8) else { throw HonchoError.invalidResponse }
        let params = try JSONDecoder().decode(SearchParams.self, from: data)

        let results = try await client.searchSession(
            sessionId: session.id,
            query: params.query,
            limit: params.limit ?? 5
        )

        if results.isEmpty {
            return encodeResult("No results found for '\(params.query)'.")
        }

        let formatted = results.enumerated().map { (i, msg) in
            "[\(i + 1)] (\(msg.peerId)) \(msg.content)"
        }.joined(separator: "\n\n")

        return encodeResult(formatted)
    }
}
```

Create `Sources/HonchoPlugin/Tools/SaveConclusionTool.swift`:

```swift
import Foundation

enum SaveConclusionTool {
    struct SaveConclusionParams: Decodable {
        let content: String
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        guard let data = payload.data(using: .utf8) else { throw HonchoError.invalidResponse }
        let params = try JSONDecoder().decode(SaveConclusionParams.self, from: data)

        let conclusions = try await client.createConclusion(
            content: params.content,
            observerId: ctx.agentPeer,
            observedId: ctx.ownerPeer,
            sessionId: session.id
        )

        let id = conclusions.first?.id ?? "unknown"
        return encodeResult("Saved conclusion (id: \(id)): \(params.content)")
    }
}
```

Create `Sources/HonchoPlugin/Tools/ProfileTool.swift`:

```swift
import Foundation

enum ProfileTool {
    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, _, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)

        let response = try await client.getPeerCard(peerId: ctx.agentPeer, target: ctx.ownerPeer)

        guard let card = response.peerCard, !card.isEmpty else {
            return encodeResult("No profile data available for the user yet.")
        }

        let formatted = card.map { "- \($0)" }.joined(separator: "\n")
        return encodeResult("## User Profile\n\(formatted)")
    }
}
```

Create `Sources/HonchoPlugin/Tools/RecallTool.swift`:

```swift
import Foundation

enum RecallTool {
    struct RecallParams: Decodable {
        let query: String
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        guard let data = payload.data(using: .utf8) else { throw HonchoError.invalidResponse }
        let params = try JSONDecoder().decode(RecallParams.self, from: data)

        let response = try await client.chat(
            peerId: ctx.agentPeer,
            body: ChatRequest(
                query: params.query,
                sessionId: session.id,
                target: ctx.ownerPeer,
                reasoningLevel: "minimal"
            )
        )

        return encodeResult(response.content ?? "No answer available.")
    }
}
```

Create `Sources/HonchoPlugin/Tools/AnalyzeTool.swift`:

```swift
import Foundation

enum AnalyzeTool {
    struct AnalyzeParams: Decodable {
        let query: String
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        guard let data = payload.data(using: .utf8) else { throw HonchoError.invalidResponse }
        let params = try JSONDecoder().decode(AnalyzeParams.self, from: data)

        let response = try await client.chat(
            peerId: ctx.agentPeer,
            body: ChatRequest(
                query: params.query,
                sessionId: session.id,
                target: ctx.ownerPeer,
                reasoningLevel: "medium"
            )
        )

        return encodeResult(response.content ?? "No analysis available.")
    }
}
```

Create `Sources/HonchoPlugin/Tools/SessionTool.swift`:

```swift
import Foundation

enum SessionTool {
    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        // Parse optional include_summary from payload
        let includeSummary: Bool = {
            guard let data = payload.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return true }
            return json["include_summary"] as? Bool ?? true
        }()

        let context = try await client.getSessionContext(
            sessionId: session.id,
            summary: includeSummary,
            peerTarget: ctx.ownerPeer,
            peerPerspective: ctx.agentPeer
        )

        var parts: [String] = ["## Session: \(sessionName)"]

        if let summary = context.summary {
            parts.append("### Summary\n\(summary.content)")
        }

        if !context.messages.isEmpty {
            let msgCount = context.messages.count
            parts.append("### Messages\n\(msgCount) message(s) in context window.")
        }

        if let rep = context.peerRepresentation, !rep.isEmpty {
            parts.append("### User Representation\n\(rep)")
        }

        return encodeResult(parts.joined(separator: "\n\n"))
    }
}
```

**Step 2: Create the shared `encodeResult` helper**

Create `Sources/HonchoPlugin/Tools/ToolHelpers.swift`:

```swift
import Foundation

/// Encode a tool result string as a JSON response.
func encodeResult(_ text: String) -> String {
    let escaped = text
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\t", with: "\\t")
    return "{\"result\": \"\(escaped)\"}"
}
```

**Step 3: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds.

**Step 4: Commit**

```bash
git add Sources/HonchoPlugin/Tools/
git commit -m "feat: add all 8 tool handlers"
```

---

### Task 8: Router

**Files:**
- Create: `Sources/HonchoPlugin/Router.swift`
- Create: `Tests/HonchoPluginTests/RouterTests.swift`

**Step 1: Write the failing test**

Create `Tests/HonchoPluginTests/RouterTests.swift`:

```swift
import XCTest
@testable import HonchoPlugin

final class RouterTests: XCTestCase {

    func testRouterReturnsErrorForUnknownTool() {
        let ctx = PluginContext()
        let result = Router.invoke(ctx: ctx, type: "tool", id: "unknown_tool", payload: "{}")
        XCTAssertTrue(result.contains("error"))
        XCTAssertTrue(result.contains("unknown_tool"))
    }

    func testRouterReturnsErrorForNonToolType() {
        let ctx = PluginContext()
        let result = Router.invoke(ctx: ctx, type: "provider", id: "honcho_context", payload: "{}")
        XCTAssertTrue(result.contains("error"))
        XCTAssertTrue(result.contains("provider"))
    }

    func testRouterReturnsErrorForMissingAPIKey() {
        let ctx = PluginContext()
        let payload = "{\"_secrets\": {}, \"_context\": {\"working_directory\": \"/tmp/test\"}}"
        let result = Router.invoke(ctx: ctx, type: "tool", id: "honcho_context", payload: payload)
        XCTAssertTrue(result.contains("error"))
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter RouterTests`
Expected: Compilation fails — `Router` not defined.

**Step 3: Write the implementation**

Create `Sources/HonchoPlugin/Router.swift`:

```swift
import Foundation

enum Router {
    static func invoke(ctx: PluginContext, type: String, id: String, payload: String) -> String {
        guard type == "tool" else {
            return encodeError("Unsupported invocation type: \(type)")
        }

        return PluginContext.invokeSync { [ctx] in
            switch id {
            case "honcho_context":
                return try await ContextTool.execute(ctx: ctx, payload: payload)
            case "honcho_save_messages":
                return try await SaveMessagesTool.execute(ctx: ctx, payload: payload)
            case "honcho_search":
                return try await SearchTool.execute(ctx: ctx, payload: payload)
            case "honcho_save_conclusion":
                return try await SaveConclusionTool.execute(ctx: ctx, payload: payload)
            case "honcho_profile":
                return try await ProfileTool.execute(ctx: ctx, payload: payload)
            case "honcho_recall":
                return try await RecallTool.execute(ctx: ctx, payload: payload)
            case "honcho_analyze":
                return try await AnalyzeTool.execute(ctx: ctx, payload: payload)
            case "honcho_session":
                return try await SessionTool.execute(ctx: ctx, payload: payload)
            default:
                return encodeError("Unknown tool: \(id)")
            }
        }
    }

    private static func encodeError(_ message: String) -> String {
        let escaped = message
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "{\"error\": \"\(escaped)\"}"
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter RouterTests`
Expected: All tests pass.

**Step 5: Commit**

```bash
git add Sources/HonchoPlugin/Router.swift Tests/HonchoPluginTests/RouterTests.swift
git commit -m "feat: add invoke router dispatching to tool handlers"
```

---

### Task 9: C ABI Entry Point

**Files:**
- Modify: `Sources/HonchoPlugin/Plugin.swift`

This is the final piece — the exported `osaurus_plugin_entry` symbol that returns the `osr_plugin_api` struct.

**Step 1: Replace the placeholder Plugin.swift**

Replace `Sources/HonchoPlugin/Plugin.swift` with:

```swift
import Foundation

// MARK: - Opaque context wrapper

private final class PluginHandle {
    let context = PluginContext()
}

// MARK: - C ABI function implementations

private func pluginInit() -> UnsafeMutableRawPointer? {
    let handle = PluginHandle()
    return Unmanaged.passRetained(handle).toOpaque()
}

private func pluginDestroy(_ rawCtx: UnsafeMutableRawPointer?) {
    guard let rawCtx else { return }
    Unmanaged<PluginHandle>.fromOpaque(rawCtx).release()
}

private func pluginGetManifest(_ rawCtx: UnsafeMutableRawPointer?) -> UnsafePointer<CChar>? {
    return strdup(Manifest.json)
}

private func pluginInvoke(
    _ rawCtx: UnsafeMutableRawPointer?,
    _ type: UnsafePointer<CChar>?,
    _ id: UnsafePointer<CChar>?,
    _ payload: UnsafePointer<CChar>?
) -> UnsafePointer<CChar>? {
    guard let rawCtx else {
        return strdup("{\"error\": \"Plugin not initialized\"}")
    }
    let handle = Unmanaged<PluginHandle>.fromOpaque(rawCtx).takeUnretainedValue()
    let typeStr = type.map { String(cString: $0) } ?? ""
    let idStr = id.map { String(cString: $0) } ?? ""
    let payloadStr = payload.map { String(cString: $0) } ?? "{}"

    let result = Router.invoke(ctx: handle.context, type: typeStr, id: idStr, payload: payloadStr)
    return strdup(result)
}

private func pluginFreeString(_ s: UnsafePointer<CChar>?) {
    free(UnsafeMutablePointer(mutating: s))
}

// MARK: - Static API table

private var api = (
    pluginFreeString,
    pluginInit,
    pluginDestroy,
    pluginGetManifest,
    pluginInvoke
)

// MARK: - Exported entry point

@_cdecl("osaurus_plugin_entry")
public func osaurusPluginEntry() -> UnsafeRawPointer {
    return withUnsafePointer(to: &api) { ptr in
        return UnsafeRawPointer(ptr)
    }
}
```

**Step 2: Build the dynamic library**

Run: `swift build -c release`
Expected: Build succeeds. The `.dylib` is at `.build/release/libHonchoPlugin.dylib`.

**Step 3: Verify the exported symbol exists**

Run: `nm -gU .build/release/libHonchoPlugin.dylib | grep osaurus_plugin_entry`
Expected: Output contains `_osaurus_plugin_entry`.

**Step 4: Run all tests**

Run: `swift test`
Expected: All tests pass.

**Step 5: Commit**

```bash
git add Sources/HonchoPlugin/Plugin.swift
git commit -m "feat: add C ABI entry point exporting osaurus_plugin_entry"
```

---

### Task 10: Clean Up and Package

**Files:**
- Delete: `Tests/HonchoPluginTests/PlaceholderTest.swift`

**Step 1: Remove placeholder test**

```bash
rm Tests/HonchoPluginTests/PlaceholderTest.swift
```

**Step 2: Run all tests one final time**

Run: `swift test`
Expected: All tests pass.

**Step 3: Build release binary**

Run: `swift build -c release`
Expected: Build succeeds.

**Step 4: Verify the dylib symbol**

Run: `nm -gU .build/release/libHonchoPlugin.dylib | grep osaurus_plugin_entry`
Expected: `_osaurus_plugin_entry` symbol is present.

**Step 5: Package for distribution**

```bash
cp .build/release/libHonchoPlugin.dylib .
zip dev.honcho.osaurus-1.0.0.zip libHonchoPlugin.dylib
rm libHonchoPlugin.dylib
```

**Step 6: Commit**

```bash
git rm Tests/HonchoPluginTests/PlaceholderTest.swift
git add -A
git commit -m "chore: clean up placeholder test and package plugin"
```

---

## Summary

| Task | Component | Files |
|------|-----------|-------|
| 1 | SwiftPM package setup | `Package.swift`, placeholder sources |
| 2 | Codable models | `Models.swift`, tests |
| 3 | Session resolver | `SessionResolver.swift`, tests |
| 4 | JSON manifest | `Manifest.swift`, tests |
| 5 | Honcho REST client | `HonchoClient.swift`, tests |
| 6 | Plugin context + async bridge | `PluginContext.swift`, tests |
| 7 | 8 tool handlers | `Tools/*.swift` |
| 8 | Router | `Router.swift`, tests |
| 9 | C ABI entry point | `Plugin.swift` |
| 10 | Cleanup and packaging | Remove placeholder, build, zip |
