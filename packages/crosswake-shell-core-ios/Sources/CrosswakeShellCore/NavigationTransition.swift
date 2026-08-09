import Foundation

/// The closed D-04 web-to-shell navigation envelope. It intentionally carries no
/// browser history, route payload, account, device, or bridge-capability state.
public struct NavigationTransition: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Equatable, Sendable { case pushPatch = "push_patch", pushNavigate = "push_navigate" }

    public let protocolName: String
    public let version: String
    public let transitionID: String
    public let kind: Kind
    public let routeID: String
    public let restorationRef: String?

    public init(protocolName: String, version: String, transitionID: String, kind: Kind, routeID: String, restorationRef: String?) {
        self.protocolName = protocolName
        self.version = version
        self.transitionID = transitionID
        self.kind = kind
        self.routeID = routeID
        self.restorationRef = restorationRef
    }

    enum CodingKeys: String, CodingKey {
        case protocolName = "protocol", version
        case transitionID = "transition_id", kind
        case routeID = "route_id", restorationRef = "restoration_ref"
    }

    public static let protocolName = "crosswake.navigation_transition"
    public static let supportedVersion = "1.0.0"
    static let requiredKeys: Set<String> = ["protocol", "version", "transition_id", "kind", "route_id"]
    static let allowedKeys = requiredKeys.union(["restoration_ref"])

    static func decode(body: Any) -> NavigationTransition? {
        guard let dictionary = body as? [String: Any],
              Set(dictionary.keys).isSubset(of: allowedKeys),
              requiredKeys.isSubset(of: Set(dictionary.keys)),
              JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary),
              let transition = try? JSONDecoder().decode(NavigationTransition.self, from: data),
              transition.protocolName == protocolName,
              transition.version == supportedVersion,
              opaque(transition.transitionID, prefix: "nav-"),
              opaque(transition.routeID, prefix: "route-"),
              transition.restorationRef.map({ opaque($0, prefix: "restore-") }) ?? true else { return nil }
        return transition
    }

    private static func opaque(_ value: String, prefix: String) -> Bool {
        value.range(of: "^" + prefix + "[0-9a-f]{16}$", options: .regularExpression) != nil
    }
}

public enum NavigationTransitionOutcome: Equatable, Sendable { case applied, denied }
