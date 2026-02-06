import XCTest
@testable import HonchoPlugin

final class RouterTests: XCTestCase {

    func testRouterReturnsErrorForUnknownTool() {
        let ctx = PluginContext()
        let result = Router.invoke(ctx: ctx, type: "tool", id: "unknown_tool", payload: "{}")
        XCTAssertTrue(result.contains("error"))
        XCTAssertTrue(result.contains("unknown_tool"))
    }

    func testRouterReturnsErrorForNonToolType() {
        let ctx = PluginContext()
        let result = Router.invoke(ctx: ctx, type: "provider", id: "honcho_context", payload: "{}")
        XCTAssertTrue(result.contains("error"))
        XCTAssertTrue(result.contains("provider"))
    }

    func testRouterReturnsErrorForMissingAPIKey() {
        let ctx = PluginContext()
        let payload = "{\"_secrets\": {}, \"_context\": {\"working_directory\": \"/tmp/test\"}}"
        let result = Router.invoke(ctx: ctx, type: "tool", id: "honcho_context", payload: payload)
        XCTAssertTrue(result.contains("error"))
    }
}
