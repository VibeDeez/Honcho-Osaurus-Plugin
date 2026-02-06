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
