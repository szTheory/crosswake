import Foundation
import SwiftUI

public enum NavigationResolution: Equatable { case authorized(ShellPresentation), denied }
public enum NavigationSelectionResult: Equatable { case authorized, denied }
public struct NavigationStackEntry: Equatable { public let routeID: String; public let presentation: ShellPresentation }

/// The sole owner of ephemeral tab and stack state. It never renders or reinterprets a leaf.
@MainActor
public final class NavigationCoordinator: ObservableObject {
    @Published public private(set) var selectedTabID: String?
    @Published public private(set) var stacks: [String: [NavigationStackEntry]] = [:]
    @Published public private(set) var activeRouteID: String?

    private let topology: NavigationTopology
    private let manifest: ShellManifest
    private let resolver: (String, ShellManifest) -> NavigationResolution

    public init(topology: NavigationTopology, manifest: ShellManifest, resolver: @escaping (String, ShellManifest) -> NavigationResolution) {
        self.topology = topology; self.manifest = manifest; self.resolver = resolver
    }

    @discardableResult public func selectRoot(routeID: String) -> NavigationSelectionResult {
        guard topology.validate(against: manifest) == .valid,
              let entry = topology.entries.first(where: { $0.routeID == routeID && $0.presentation == .root }),
              case let .authorized(presentation) = resolver(routeID, manifest) else { return .denied }
        let stackEntry = NavigationStackEntry(routeID: entry.routeID, presentation: presentation)
        selectedTabID = entry.rootTabID
        stacks[entry.rootTabID] = [stackEntry]
        activeRouteID = entry.routeID
        return .authorized
    }
}
