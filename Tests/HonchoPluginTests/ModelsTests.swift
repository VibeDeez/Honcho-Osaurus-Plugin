import XCTest
@testable import HonchoPlugin

final class ModelsTests: XCTestCase {

    func testPeerCreateEncodesToJSON() throws {
        let peer = PeerCreate(id: "owner", metadata: [:])
        let data = try JSONEncoder().encode(peer)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["id"] as? String, "owner")
    }

    func testPeerDecodeFromJSON() throws {
        let json = """
        {"id":"owner","workspace_id":"osaurus","created_at":"2025-01-01T00:00:00Z","metadata":{},"configuration":{}}
        """.data(using: .utf8)!
        let peer = try JSONDecoder().decode(Peer.self, from: json)
        XCTAssertEqual(peer.id, "owner")
        XCTAssertEqual(peer.workspaceId, "osaurus")
    }

    func testSessionCreateEncodesToJSON() throws {
        let session = SessionCreate(
            id: "my-project",
            metadata: [:],
            peers: ["owner": SessionPeerConfig(observeMe: true, observeOthers: false)]
        )
        let data = try JSONEncoder().encode(session)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["id"] as? String, "my-project")
        let peers = json["peers"] as? [String: Any]
        XCTAssertNotNil(peers?["owner"])
    }

    func testSessionDecodeFromJSON() throws {
        let json = """
        {"id":"my-project","is_active":true,"workspace_id":"osaurus","metadata":{},"configuration":{},"created_at":"2025-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let session = try JSONDecoder().decode(Session.self, from: json)
        XCTAssertEqual(session.id, "my-project")
        XCTAssertTrue(session.isActive)
    }

    func testMessageInputEncodesToJSON() throws {
        let msg = MessageInput(content: "Hello", peerId: "owner", metadata: nil)
        let data = try JSONEncoder().encode(msg)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["content"] as? String, "Hello")
        XCTAssertEqual(json["peer_id"] as? String, "owner")
    }

    func testMessageDecodeFromJSON() throws {
        let json = """
        {"id":"msg-1","content":"Hello","peer_id":"owner","session_id":"s1","metadata":{},"created_at":"2025-01-01T00:00:00Z","workspace_id":"osaurus","token_count":5}
        """.data(using: .utf8)!
        let msg = try JSONDecoder().decode(Message.self, from: json)
        XCTAssertEqual(msg.id, "msg-1")
        XCTAssertEqual(msg.content, "Hello")
        XCTAssertEqual(msg.tokenCount, 5)
    }

    func testSessionContextDecodeFromJSON() throws {
        let json = """
        {
          "id": "ctx-1",
          "messages": [],
          "summary": {"content":"summary text","message_id":"m1","summary_type":"short","created_at":"2025-01-01T00:00:00Z","token_count":10},
          "peer_representation": "Knows Swift",
          "peer_card": ["Likes coding", "Uses macOS"]
        }
        """.data(using: .utf8)!
        let ctx = try JSONDecoder().decode(SessionContext.self, from: json)
        XCTAssertEqual(ctx.peerRepresentation, "Knows Swift")
        XCTAssertEqual(ctx.peerCard?.count, 2)
        XCTAssertEqual(ctx.summary?.content, "summary text")
    }

    func testConclusionCreateEncodesToJSON() throws {
        let c = ConclusionCreate(content: "User likes Swift", observerId: "osaurus", observedId: "owner", sessionId: "s1")
        let data = try JSONEncoder().encode(c)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["content"] as? String, "User likes Swift")
        XCTAssertEqual(json["observer_id"] as? String, "osaurus")
        XCTAssertEqual(json["observed_id"] as? String, "owner")
        XCTAssertEqual(json["session_id"] as? String, "s1")
    }

    func testConclusionDecodeFromJSON() throws {
        let json = """
        {"id":"c-1","content":"User likes Swift","observer_id":"osaurus","observed_id":"owner","session_id":"s1","created_at":"2025-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let c = try JSONDecoder().decode(Conclusion.self, from: json)
        XCTAssertEqual(c.id, "c-1")
        XCTAssertEqual(c.content, "User likes Swift")
    }

    func testChatRequestEncodesToJSON() throws {
        let req = ChatRequest(query: "What does the user like?", sessionId: "s1", target: "owner", reasoningLevel: "minimal")
        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["query"] as? String, "What does the user like?")
        XCTAssertEqual(json["reasoning_level"] as? String, "minimal")
    }

    func testChatResponseDecodeFromJSON() throws {
        let json = """
        {"content":"The user enjoys programming in Swift."}
        """.data(using: .utf8)!
        let resp = try JSONDecoder().decode(ChatResponse.self, from: json)
        XCTAssertEqual(resp.content, "The user enjoys programming in Swift.")
    }

    func testRepresentationRequestEncodesToJSON() throws {
        let req = RepresentationRequest(searchQuery: "preferences", searchTopK: 5)
        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["search_query"] as? String, "preferences")
        XCTAssertEqual(json["search_top_k"] as? Int, 5)
    }

    func testRepresentationResponseDecodeFromJSON() throws {
        let json = """
        {"representation":"User is a Swift developer who prefers clean code."}
        """.data(using: .utf8)!
        let resp = try JSONDecoder().decode(RepresentationResponse.self, from: json)
        XCTAssertEqual(resp.representation, "User is a Swift developer who prefers clean code.")
    }

    func testWorkspaceCreateEncodesToJSON() throws {
        let ws = WorkspaceCreate(id: "osaurus", metadata: [:])
        let data = try JSONEncoder().encode(ws)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["id"] as? String, "osaurus")
    }

    func testSessionSummariesDecodeFromJSON() throws {
        let json = """
        {
          "id": "s1",
          "short_summary": {"content":"Short","message_id":"m1","summary_type":"short","created_at":"2025-01-01T00:00:00Z","token_count":5},
          "long_summary": null
        }
        """.data(using: .utf8)!
        let s = try JSONDecoder().decode(SessionSummaries.self, from: json)
        XCTAssertEqual(s.shortSummary?.content, "Short")
        XCTAssertNil(s.longSummary)
    }

    func testPeerCardResponseDecodeFromJSON() throws {
        let json = """
        {"peer_card": ["Fact 1", "Fact 2"]}
        """.data(using: .utf8)!
        let resp = try JSONDecoder().decode(PeerCardResponse.self, from: json)
        XCTAssertEqual(resp.peerCard?.count, 2)
    }

    func testSearchRequestEncodesToJSON() throws {
        let req = SearchRequest(query: "swift programming", limit: 5)
        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["query"] as? String, "swift programming")
        XCTAssertEqual(json["limit"] as? Int, 5)
    }
}
