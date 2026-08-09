import Foundation

/// A bounded, manifest-derived topology. Route IDs and tab IDs are opaque contract references;
/// host presentation remains outside this package.
public struct NavigationTopology: Codable, Equatable {
    public let topologySchemaVersion: String
    public let manifestSchemaVersion: String
    public let status: NavigationTopologyStatus
    public let entries: [NavigationTopologyEntry]

    public init(topologySchemaVersion: String, manifestSchemaVersion: String, status: NavigationTopologyStatus, entries: [NavigationTopologyEntry]) {
        self.topologySchemaVersion = topologySchemaVersion
        self.manifestSchemaVersion = manifestSchemaVersion
        self.status = status
        self.entries = entries
    }

    enum CodingKeys: String, CodingKey {
        case topologySchemaVersion = "topology_schema_version"
        case manifestSchemaVersion = "manifest_schema_version"
        case status, entries
    }

    public func validate(against manifest: ShellManifest) -> NavigationTopologyValidation {
        guard status == .ready else { return .denied(.unknownBlocking) }
        guard topologySchemaVersion == manifestSchemaVersion else { return .denied(.compatibilityMismatch) }
        guard entries.isEmpty == false else { return .denied(.unknownBlocking) }

        var routeIDs = Set<String>()
        var rootTabs = Set<String>()
        for entry in entries {
            guard Self.isOpaqueRouteID(entry.routeID), manifest.routes[entry.routeID] != nil else { return .denied(.unknownRoute) }
            guard routeIDs.insert(entry.routeID).inserted else { return .denied(.duplicateRoute) }
            switch entry.presentation {
            case .root:
                guard entry.parentRouteID == nil, rootTabs.insert(entry.rootTabID).inserted else { return .denied(.invalidGraph) }
            case .push:
                guard let parent = entry.parentRouteID, parent != entry.routeID, entries.contains(where: { $0.routeID == parent && $0.rootTabID == entry.rootTabID }) else { return .denied(.invalidGraph) }
            }
        }
        guard entries.allSatisfy({ reachesRoot($0, visited: []) }) else { return .denied(.invalidGraph) }
        return .valid
    }

    private func reachesRoot(_ entry: NavigationTopologyEntry, visited: Set<String>) -> Bool {
        if entry.presentation == .root { return true }
        guard visited.contains(entry.routeID) == false,
              let parentID = entry.parentRouteID,
              let parent = entries.first(where: { $0.routeID == parentID }) else { return false }
        return reachesRoot(parent, visited: visited.union([entry.routeID]))
    }

    private static func isOpaqueRouteID(_ value: String) -> Bool {
        value.range(of: "^route-[0-9a-f]{16}$", options: .regularExpression) != nil
    }
}

public enum NavigationTopologyStatus: String, Codable, Equatable { case ready, unknownBlocking = "unknown_blocking" }
public enum NavigationPresentation: String, Codable, Equatable { case root, push }
public enum NavigationEntryPosture: String, Codable, Equatable { case allow, deny }
public enum NavigationTopologyDenial: String, Codable, Equatable { case unknownBlocking = "unknown_blocking", compatibilityMismatch = "compatibility_mismatch", unknownRoute = "unknown_route", duplicateRoute = "duplicate_route", invalidGraph = "invalid_graph" }
public enum NavigationTopologyValidation: Equatable { case valid, denied(NavigationTopologyDenial) }

public struct NavigationTopologyEntry: Codable, Equatable {
    public let routeID: String
    public let rootTabID: String
    public let presentation: NavigationPresentation
    public let parentRouteID: String?
    public let deepLinkPosture: NavigationEntryPosture
    public let restorationPosture: NavigationEntryPosture

    public init(routeID: String, rootTabID: String, presentation: NavigationPresentation, parentRouteID: String?, deepLinkPosture: NavigationEntryPosture, restorationPosture: NavigationEntryPosture) {
        self.routeID = routeID; self.rootTabID = rootTabID; self.presentation = presentation; self.parentRouteID = parentRouteID; self.deepLinkPosture = deepLinkPosture; self.restorationPosture = restorationPosture
    }

    enum CodingKeys: String, CodingKey {
        case routeID = "route_id"; case rootTabID = "root_tab_id"; case presentation
        case parentRouteID = "parent_route_id"; case deepLinkPosture = "deep_link_posture"; case restorationPosture = "restoration_posture"
    }
}
