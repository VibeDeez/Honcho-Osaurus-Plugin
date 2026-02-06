import Foundation

enum SaveConclusionTool {
    struct SaveConclusionParams: Decodable {
        let content: String
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        let params = try ctx.decodeParams(SaveConclusionParams.self, from: payload)

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
