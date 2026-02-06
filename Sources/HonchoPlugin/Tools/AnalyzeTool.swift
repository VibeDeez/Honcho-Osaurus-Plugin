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
