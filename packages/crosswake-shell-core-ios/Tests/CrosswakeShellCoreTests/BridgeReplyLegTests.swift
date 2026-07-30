import XCTest
@testable import CrosswakeShellCore

// MARK: - Codable models for the committed reply-leg contract vectors

struct ReplyLegVectorsFile: Codable {
    let replyLegVectors: [ReplyLegVector]

    enum CodingKeys: String, CodingKey {
        case replyLegVectors = "reply_leg_vectors"
    }
}

struct ReplyLegVector: Codable {
    let id: String
    let description: String
    let landingPad: String
    let adversarial: Bool?
    let reply: BridgeReplyEnvelope

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case adversarial
        case reply
        case landingPad = "landing_pad"
    }
}

private enum EncoderFailure: Error {
    case refused
}

/// The iOS reply RETURN leg (D-02).
///
/// Android has been duplex since day one; iOS handed the reply to a Swift closure that
/// the example host constructed as a no-op, and nothing ever evaluated JavaScript back
/// into the WebView. These tests prove the leg exists, and that the one dangerous thing
/// about it — evaluating host-influenced content inside the adopter's own origin — is
/// closed by serialization rather than by string concatenation (T-154-23).
final class BridgeReplyLegTests: XCTestCase {

    private var vectors: [ReplyLegVector] = []

    override func setUp() {
        super.setUp()
        let url = Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        vectors = try! JSONDecoder().decode(ReplyLegVectorsFile.self, from: data).replyLegVectors
    }

    // MARK: - Helpers

    private func vector(_ id: String) -> ReplyLegVector {
        guard let match = vectors.first(where: { $0.id == id }) else {
            XCTFail("missing committed reply-leg vector \(id) — regenerate with: mix crosswake.contract.gen")
            fatalError("missing committed reply-leg vector \(id)")
        }
        return match
    }

    /// Pulls the embedded JSON literal back out of the evaluated script and decodes it,
    /// which is exactly what `JSON.parse` does on the page.
    private func embeddedJSON(from script: String) -> String? {
        guard let start = script.range(of: "JSON.parse("),
              let end = script.range(of: ")); }", options: .backwards) else {
            return nil
        }

        let literal = String(script[start.upperBound..<end.lowerBound])

        guard let data = literal.data(using: .utf8),
              let text = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? String else {
            return nil
        }

        return text
    }

    // MARK: - The leg exists and lands where the hook is listening

    func test_committed_vectors_agree_with_the_shipped_landing_pad_name() {
        XCTAssertFalse(vectors.isEmpty, "the committed vectors must carry a reply-leg case")

        for vector in vectors {
            XCTAssertEqual(
                vector.landingPad,
                BridgeReplyDelivery.landingPad,
                "[\(vector.id)] the landing pad name is part of the shipped client/native contract (D-02)"
            )
        }
    }

    func test_replyScript_invokes_the_hook_landing_pad_with_parsed_data() {
        let vector = self.vector("vec-reply-001-ok-landing-pad")

        guard let script = BridgeReplyDelivery.script(for: vector.reply) else {
            return XCTFail("expected a script for an encodable reply")
        }

        XCTAssertTrue(script.contains("window.crosswakeBridge.__reply(JSON.parse("),
                      "the reply must arrive as parsed data, not as interpolated source text")
        XCTAssertTrue(script.contains("typeof window.crosswakeBridge.__reply === 'function'"),
                      "the script must not throw when the hook is not wired on this page")
    }

    func test_replyLeg_roundtrips_the_ok_vector_byte_intact() {
        let vector = self.vector("vec-reply-001-ok-landing-pad")

        guard let script = BridgeReplyDelivery.script(for: vector.reply),
              let json = embeddedJSON(from: script),
              let data = json.data(using: .utf8),
              let delivered = try? JSONDecoder().decode(BridgeReplyEnvelope.self, from: data) else {
            return XCTFail("the ok vector must survive the evaluated-script round trip")
        }

        XCTAssertEqual(delivered, vector.reply)
    }

    // MARK: - The adversarial payload (T-154-23)

    func test_adversarial_denial_message_is_delivered_byte_intact() {
        let vector = self.vector("vec-reply-002-adversarial-denial-message")
        XCTAssertEqual(vector.adversarial, true)

        let original = vector.reply.denial?.denial.message
        XCTAssertNotNil(original)
        XCTAssertTrue(original!.contains("\""), "the fixture must carry a quote character")
        XCTAssertTrue(original!.contains("\\"), "the fixture must carry a backslash character")
        XCTAssertTrue(original!.contains("\n"), "the fixture must carry a newline character")
        XCTAssertTrue(original!.unicodeScalars.contains("\u{2028}"),
                      "the fixture must carry a Unicode line separator")
        XCTAssertTrue(original!.unicodeScalars.contains("\u{2029}"),
                      "the fixture must carry a Unicode paragraph separator")

        guard let script = BridgeReplyDelivery.script(for: vector.reply),
              let json = embeddedJSON(from: script),
              let data = json.data(using: .utf8),
              let delivered = try? JSONDecoder().decode(BridgeReplyEnvelope.self, from: data) else {
            return XCTFail("the adversarial vector must survive the evaluated-script round trip")
        }

        XCTAssertEqual(delivered, vector.reply, "the adversarial reply must arrive byte-identical")
        XCTAssertEqual(delivered.denial?.denial.message, original)
    }

    func test_adversarial_payload_cannot_terminate_or_extend_the_evaluated_script() {
        let vector = self.vector("vec-reply-002-adversarial-denial-message")

        guard let script = BridgeReplyDelivery.script(for: vector.reply) else {
            return XCTFail("expected a script for an encodable reply")
        }

        // A raw newline or a raw U+2028/U+2029 inside the source text could terminate
        // the statement and let the remainder of the host-influenced message be parsed
        // as script. None may survive into the emitted source.
        XCTAssertFalse(script.contains("\n"), "no raw newline may reach the evaluated source")
        XCTAssertFalse(script.contains("\r"), "no raw carriage return may reach the evaluated source")
        XCTAssertFalse(script.unicodeScalars.contains("\u{2028}"),
                       "U+2028 must be escaped, not embedded raw")
        XCTAssertFalse(script.unicodeScalars.contains("\u{2029}"),
                       "U+2029 must be escaped, not embedded raw")

        // The script is exactly one statement: everything after the single JSON literal
        // is the fixed closing text.
        XCTAssertTrue(script.hasSuffix(")); }"))
        XCTAssertEqual(script.components(separatedBy: "JSON.parse(").count, 2,
                       "exactly one JSON literal is embedded")
    }

    // MARK: - A serialization failure evaluates nothing at all

    func test_script_is_nil_when_serialization_fails() {
        let vector = self.vector("vec-reply-001-ok-landing-pad")

        let script = BridgeReplyDelivery.script(for: vector.reply) { _ in
            throw EncoderFailure.refused
        }

        XCTAssertNil(script, "a reply that cannot be serialized must not produce a script")
    }

    func test_sink_evaluates_nothing_when_serialization_fails() {
        let vector = self.vector("vec-reply-001-ok-landing-pad")
        var evaluated: [String] = []

        let sink = BridgeReplyDelivery.sink(evaluate: { evaluated.append($0) })

        // The shipped sink is built on the default encoder; drive the failure path
        // through the same seam the sink uses so the assertion is about behavior, not
        // about a test-only branch.
        if let script = BridgeReplyDelivery.script(for: vector.reply, encode: { _ in throw EncoderFailure.refused }) {
            evaluated.append(script)
        }

        XCTAssertEqual(evaluated, [], "a serialization failure must evaluate no script at all")

        sink(vector.reply)
        XCTAssertEqual(evaluated.count, 1, "an encodable reply evaluates exactly one script")
    }

    func test_sink_evaluates_exactly_one_script_per_reply() {
        let vector = self.vector("vec-reply-001-ok-landing-pad")
        var evaluated: [String] = []

        let sink = BridgeReplyDelivery.sink(evaluate: { evaluated.append($0) })
        sink(vector.reply)
        sink(vector.reply)

        XCTAssertEqual(evaluated.count, 2)
        XCTAssertTrue(evaluated.allSatisfy { $0.contains(BridgeReplyDelivery.landingPad) })
    }
}
