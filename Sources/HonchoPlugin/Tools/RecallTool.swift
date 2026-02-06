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
