import Foundation

// MARK: - JSON Response Helpers

private struct ResultWrapper: Encodable {
    let result: String
}

private struct ErrorWrapper: Encodable {
    let error: String
}

private let responseEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    return encoder
}()

/// Encode a tool result string as a JSON response.
func encodeResult(_ text: String) -> String {
    guard let data = try? responseEncoder.encode(ResultWrapper(result: text)) else {
        return "{\"result\": \"encoding error\"}"
    }
    return String(data: data, encoding: .utf8) ?? "{\"result\": \"encoding error\"}"
}

/// Encode an error message as a JSON response.
func encodeError(_ message: String) -> String {
    guard let data = try? responseEncoder.encode(ErrorWrapper(error: message)) else {
        return "{\"error\": \"encoding error\"}"
    }
    return String(data: data, encoding: .utf8) ?? "{\"error\": \"encoding error\"}"
}
