import Foundation

enum ProfileTool {
    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, _, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)

        let response = try await client.getPeerCard(peerId: ctx.agentPeer, target: ctx.ownerPeer)

        guard let card = response.peerCard, !card.isEmpty else {
            return encodeResult("No profile data available for the user yet.")
        }

        let formatted = card.map { "- \($0)" }.joined(separator: "\n")
        return encodeResult("## User Profile\n\(formatted)")
    }
}
