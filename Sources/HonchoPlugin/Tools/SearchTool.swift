import Foundation

enum SearchTool {
    struct SearchParams: Decodable {
        let query: String
        let limit: Int?
    }

    static func execute(ctx: PluginContext, payload: String) async throws -> String {
        let (_, sessionName, client) = try ctx.parsePayload(payload)
        try await ctx.ensureInitialized(client: client)
        let session = try await ctx.ensureSession(client: client, sessionName: sessionName)

        let params = try ctx.decodeParams(SearchParams.self, from: payload)

        let results = try await client.searchSession(
            sessionId: session.id,
            query: params.query,
            limit: params.limit ?? 5
        )

        if results.isEmpty {
            return encodeResult("No results found for '\(params.query)'.")
        }

        let formatted = results.enumerated().map { (i, msg) in
            "[\(i + 1)] (\(msg.peerId)) \(msg.content)"
        }.joined(separator: "\n\n")

        return encodeResult(formatted)
    }
}
