import XCTest
@testable import HonchoPlugin

final class SessionResolverTests: XCTestCase {

    func testResolvesLastPathComponent() {
        let name = SessionResolver.resolve(workingDirectory: "/Users/alice/projects/my-app")
        XCTAssertEqual(name, "my-app")
    }

    func testResolvesWithTrailingSlash() {
        let name = SessionResolver.resolve(workingDirectory: "/Users/alice/projects/my-app/")
        XCTAssertEqual(name, "my-app")
    }

    func testFallsBackToDefaultWhenNil() {
        let name = SessionResolver.resolve(workingDirectory: nil)
        XCTAssertEqual(name, "default")
    }

    func testFallsBackToDefaultWhenEmpty() {
        let name = SessionResolver.resolve(workingDirectory: "")
        XCTAssertEqual(name, "default")
    }

    func testFallsBackToDefaultWhenRootSlash() {
        let name = SessionResolver.resolve(workingDirectory: "/")
        XCTAssertEqual(name, "default")
    }

    func testSanitizesSpecialCharacters() {
        let name = SessionResolver.resolve(workingDirectory: "/Users/alice/My Project (v2)")
        XCTAssertEqual(name, "My-Project--v2-")
    }

    func testPreservesHyphensAndUnderscores() {
        let name = SessionResolver.resolve(workingDirectory: "/Users/alice/my_cool-project")
        XCTAssertEqual(name, "my_cool-project")
    }
}
