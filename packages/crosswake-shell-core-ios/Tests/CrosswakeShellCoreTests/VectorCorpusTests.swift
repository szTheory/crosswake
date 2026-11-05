import XCTest
@testable import CrosswakeShellCore

final class VectorCorpusTests: XCTestCase {
    private func corpusURL() throws -> URL {
        try XCTUnwrap(
            Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json"),
            "CW-VECTOR-MISSING bridge_contract_vectors.json"
        )
    }

    func testCorpusBytesMatchGeneratedVectorSetHash() throws {
        let data = try VectorCorpus.verifiedData(contentsOf: try corpusURL())
        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(VectorSet.sha256.count, 64)
        XCTAssertTrue(VectorSet.sha256.allSatisfy { "0123456789abcdef".contains($0) })
        XCTAssertEqual(VectorCorpus.sha256Hex(data), VectorSet.sha256)
    }

    func testOneFlippedByteFailsWithVectorHashMismatch() throws {
        var data = try VectorCorpus.verifiedData(contentsOf: try corpusURL())
        data[data.count / 2] ^= 0x01
        XCTAssertThrowsError(try VectorCorpus.verify(data, expected: VectorSet.sha256)) { error in
            XCTAssertTrue(
                String(describing: error).hasPrefix("CW-VECTOR-HASH"),
                "unexpected error: \(error)"
            )
        }
    }
}
