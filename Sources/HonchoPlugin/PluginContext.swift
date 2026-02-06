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
                result = encodeError(error.localizedDescription)
            }
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    /// Get or create a HonchoClient for the given API key.
    func client(apiKey: String) -> HonchoClient {
        if let cached = cachedClient, cachedApiKey == apiKey {
            return cached
        }
        let c = HonchoClient(apiKey: apiKey, workspaceId: defaultWorkspaceId)
        cachedClient = c
        cachedApiKey = apiKey
        return c
    }

    /// Ensure workspace and peers exist. Idempotent.
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

    /// Decode tool-specific parameters from the payload JSON.
    func decodeParams<T: Decodable>(_ type: T.Type, from payloadJSON: String) throws -> T {
        guard let data = payloadJSON.data(using: .utf8) else {
            throw HonchoError.invalidResponse
        }
        return try JSONDecoder().decode(type, from: data)
    }

    var ownerPeer: String { ownerPeerId }
    var agentPeer: String { agentPeerId }
}
