import Foundation

enum ContextTool {
    private struct ContextParams: Decodable {
        let searchQuery: String?

        enum CodingKeys: String, CodingKey {
            case searchQuery = "search_query"
        }
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        let params = try ctx.decodeParams(ContextParams.self, from: payload)

        let context = try await client.getSessionContext(
            sessionId: session.id,
            searchQuery: params.searchQuery,
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
