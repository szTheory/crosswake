import Foundation

public struct ServerEvent: Equatable {
    public let name: String
    public let payload: [String: String]

    public init(name: String, payload: [String: String] = [:]) {
        self.name = name
        self.payload = payload
    }
}
