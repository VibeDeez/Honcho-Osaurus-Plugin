import Foundation

enum SessionResolver {
    private static let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    private static let maxLength = 100

    static func resolve(workingDirectory: String?) -> String {
        guard let dir = workingDirectory, !dir.isEmpty else {
            return "default"
        }

        let lastComponent = URL(fileURLWithPath: dir).lastPathComponent

        guard lastComponent != "/" && !lastComponent.isEmpty else {
            return "default"
        }

        let sanitized = String(lastComponent.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? Character(scalar) : Character("-")
        })

        guard !sanitized.isEmpty else {
            return "default"
        }

        return String(sanitized.prefix(maxLength))
    }
}
