import Foundation

enum AnalyzeTool {
    struct AnalyzeParams: Decodable {
        let query: String
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        let params = try ctx.decodeParams(AnalyzeParams.self, from: payload)

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
