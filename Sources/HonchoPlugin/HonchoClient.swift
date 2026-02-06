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

    // MARK: - URL and Request Building

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

    // MARK: - Workspace

    func getOrCreateWorkspace() async throws -> Workspace {
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
