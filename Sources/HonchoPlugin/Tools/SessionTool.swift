import Foundation

enum SessionTool {
    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

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
