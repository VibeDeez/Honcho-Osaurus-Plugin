import Foundation

enum SaveMessagesTool {
    struct SaveMessagesParams: Decodable {
        let messages: [MessageParam]

        struct MessageParam: Decodable {
            let role: String
            let content: String
        }
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        let params = try ctx.decodeParams(SaveMessagesParams.self, from: payload)

        let inputs = params.messages.map { msg in
            let peerId = msg.role == "user" ? ctx.ownerPeer : ctx.agentPeer
            return MessageInput(content: msg.content, peerId: peerId, metadata: nil)
        }

        let saved = try await client.createMessages(sessionId: session.id, messages: inputs)
        return encodeResult("Saved \(saved.count) message(s) to session '\(sessionName)'.")
    }
}
