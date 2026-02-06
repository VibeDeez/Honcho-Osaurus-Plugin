import XCTest
@testable import HonchoPlugin

final class HonchoClientTests: XCTestCase {

    func testBuildURLConstructsCorrectPath() {
        let client = HonchoClient(apiKey: "hch-test", workspaceId: "osaurus")
        let url = client.buildURL(path: "/peers")
        XCTAssertEqual(url?.absoluteString, "https://api.honcho.dev/v3/workspaces/osaurus/peers")
    }

    func testBuildURLWithQueryParams() {
        let client = HonchoClient(apiKey: "hch-test", workspaceId: "osaurus")
        let url = client.buildURL(path: "/sessions/s1/context", queryItems: [
            URLQueryItem(name: "summary", value: "true"),
            URLQueryItem(name: "peer_target", value: "owner")
        ])
        let urlString = url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("summary=true"))
        XCTAssertTrue(urlString.contains("peer_target=owner"))
    }

    func testBuildRequestSetsAuthHeader() {
        let client = HonchoClient(apiKey: "hch-test-key", workspaceId: "osaurus")
        let url = URL(string: "https://api.honcho.dev/v3/workspaces/osaurus/peers")!
        let request = client.buildRequest(url: url, method: "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer hch-test-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testBuildRequestSetsMethod() {
        let client = HonchoClient(apiKey: "hch-test", workspaceId: "osaurus")
        let url = URL(string: "https://api.honcho.dev/v3/workspaces/osaurus/peers")!
        let getReq = client.buildRequest(url: url, method: "GET")
        XCTAssertEqual(getReq.httpMethod, "GET")
        let postReq = client.buildRequest(url: url, method: "POST")
        XCTAssertEqual(postReq.httpMethod, "POST")
    }

    func testCustomBaseURL() {
        let client = HonchoClient(apiKey: "hch-test", workspaceId: "osaurus", baseURL: "http://localhost:8000/v3")
        let url = client.buildURL(path: "/peers")
        XCTAssertEqual(url?.absoluteString, "http://localhost:8000/v3/workspaces/osaurus/peers")
    }
}
