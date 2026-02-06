import Foundation

enum SessionResolver {
    static func resolve(workingDirectory: String?) -> String {
        guard let dir = workingDirectory, !dir.isEmpty else {
            return "default"
        }

        let url = URL(fileURLWithPath: dir)
        let lastComponent = url.lastPathComponent

        if lastComponent == "/" || lastComponent.isEmpty {
            return "default"
        }

        let sanitized = lastComponent.map { c -> Character in
            if c.isLetter || c.isNumber || c == "-" || c == "_" {
                return c
            }
            return "-"
        }

        let result = String(sanitized)
        if result.isEmpty {
            return "default"
        }

        return String(result.prefix(100))
    }
}
