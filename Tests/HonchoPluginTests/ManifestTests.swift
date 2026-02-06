import XCTest
@testable import HonchoPlugin

final class ManifestTests: XCTestCase {

    func testManifestIsValidJSON() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(obj["plugin_id"] as? String, "dev.honcho.osaurus")
        XCTAssertEqual(obj["version"] as? String, "1.0.0")
    }

    func testManifestHasEightTools() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let capabilities = obj["capabilities"] as! [String: Any]
        let tools = capabilities["tools"] as! [[String: Any]]
        XCTAssertEqual(tools.count, 8)
    }

    func testManifestHasOneSecret() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let secrets = obj["secrets"] as! [[String: Any]]
        XCTAssertEqual(secrets.count, 1)
        XCTAssertEqual(secrets[0]["id"] as? String, "honcho_api_key")
        XCTAssertEqual(secrets[0]["required"] as? Bool, true)
    }

    func testManifestToolIds() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let capabilities = obj["capabilities"] as! [String: Any]
        let tools = capabilities["tools"] as! [[String: Any]]
        let ids = tools.map { $0["id"] as! String }.sorted()
        XCTAssertEqual(ids, [
            "honcho_analyze",
            "honcho_context",
            "honcho_profile",
            "honcho_recall",
            "honcho_save_conclusion",
            "honcho_save_messages",
            "honcho_search",
            "honcho_session"
        ])
    }

    func testWriteToolsHaveAskPermission() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let capabilities = obj["capabilities"] as! [String: Any]
        let tools = capabilities["tools"] as! [[String: Any]]
        let writeTools = tools.filter { ["honcho_save_messages", "honcho_save_conclusion"].contains($0["id"] as? String) }
        for tool in writeTools {
            XCTAssertEqual(tool["permission_policy"] as? String, "ask")
        }
    }

    func testReadToolsHaveAutoPermission() throws {
        let json = Manifest.json
        let data = json.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let capabilities = obj["capabilities"] as! [String: Any]
        let tools = capabilities["tools"] as! [[String: Any]]
        let readToolIds = ["honcho_context", "honcho_search", "honcho_profile", "honcho_recall", "honcho_analyze", "honcho_session"]
        let readTools = tools.filter { readToolIds.contains($0["id"] as? String ?? "") }
        XCTAssertEqual(readTools.count, 6)
        for tool in readTools {
            XCTAssertEqual(tool["permission_policy"] as? String, "auto")
        }
    }
}