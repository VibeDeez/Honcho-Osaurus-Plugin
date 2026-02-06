import Foundation

enum Router {
    static func invoke(ctx: PluginContext, type: String, id: String, payload: String) -> String {
        guard type == "tool" else {
            return encodeError("Unsupported invocation type: \(type)")
        }

        return PluginContext.invokeSync { [ctx] in
            switch id {
            case "honcho_context":
                return try await ContextTool.execute(ctx: ctx, payload: payload)
            case "honcho_save_messages":
                return try await SaveMessagesTool.execute(ctx: ctx, payload: payload)
            case "honcho_search":
                return try await SearchTool.execute(ctx: ctx, payload: payload)
            case "honcho_save_conclusion":
                return try await SaveConclusionTool.execute(ctx: ctx, payload: payload)
            case "honcho_profile":
                return try await ProfileTool.execute(ctx: ctx, payload: payload)
            case "honcho_recall":
                return try await RecallTool.execute(ctx: ctx, payload: payload)
            case "honcho_analyze":
                return try await AnalyzeTool.execute(ctx: ctx, payload: payload)
            case "honcho_session":
                return try await SessionTool.execute(ctx: ctx, payload: payload)
            default:
                return encodeError("Unknown tool: \(id)")
            }
        }
    }

    private static func encodeError(_ message: String) -> String {
        let escaped = message
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "{\"error\": \"\(escaped)\"}"
    }
}
