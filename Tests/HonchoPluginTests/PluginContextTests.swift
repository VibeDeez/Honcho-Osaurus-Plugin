import XCTest
@testable import HonchoPlugin

final class PluginContextTests: XCTestCase {

    func testInvokeSyncReturnsResult() {
        let result = PluginContext.invokeSync {
            return "hello"
        }
        XCTAssertEqual(result, "hello")
    }

    func testInvokeSyncReturnsErrorJSON() {
        let result = PluginContext.invokeSync {
            throw HonchoError.missingAPIKey
        }
        XCTAssertTrue(result.contains("error"))
        XCTAssertTrue(result.contains("app.honcho.dev"))
    }

    func testExtractAPIKeyFromPayload() throws {
        let json = """
        {"_secrets": {"honcho_api_key": "hch-test123"}, "_context": {"working_directory": "/tmp/test"}}
        """
        let payload = try JSONDecoder().decode(InvocationPayload.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(payload.secrets?["honcho_api_key"], "hch-test123")
        XCTAssertEqual(payload.context?.workingDirectory, "/tmp/test")
    }

    func testExtractAPIKeyMissingReturnsNil() throws {
        let json = """
        {"_secrets": {}, "_context": {"working_directory": "/tmp/test"}}
        """
        let payload = try JSONDecoder().decode(InvocationPayload.self, from: json.data(using: .utf8)!)
        XCTAssertNil(payload.secrets?["honcho_api_key"])
    }
}
