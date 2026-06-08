import Foundation

public enum ConnectionState: Equatable {
    case connecting
    case connected
    case disconnected
    case retrying
}
