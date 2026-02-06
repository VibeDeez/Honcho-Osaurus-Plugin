import Foundation

enum SessionTool {
    private struct SessionParams: Decodable {
        let includeSummary: Bool?

        enum CodingKeys: String, CodingKey {
            case includeSummary = "include_summary"
        }
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        let params = try ctx.decodeParams(SessionParams.self, from: payload)

        let context = try await client.getSessionContext(
            sessionId: session.id,
            summary: params.includeSummary ?? true,
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
