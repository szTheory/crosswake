import CryptoKit
import Foundation

/// The only way the Swift tests turn bridge-corpus bytes into parsed vectors. It checks the bytes
/// against the generated `VectorSet.sha256` before any decoder sees them, so Swift runs exactly the
/// bytes `mix crosswake.contract.gen` wrote (D-04, D-05).
enum VectorCorpusError: Error, CustomStringConvertible {
    case hashMismatch(expected: String, actual: String)

    var description: String {
        switch self {
        case let .hashMismatch(expected, actual):
            return "CW-VECTOR-HASH expected \(expected) got \(actual)"
        }
    }
}

enum VectorCorpus {
    static func verifiedData(contentsOf url: URL) throws -> Data {
        let data = try Data(contentsOf: url)
        return try verify(data, expected: VectorSet.sha256)
    }

    static func verify(_ data: Data, expected: String) throws -> Data {
        let actual = sha256Hex(data)
        guard actual == expected else {
            throw VectorCorpusError.hashMismatch(expected: expected, actual: actual)
        }
        return data
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
