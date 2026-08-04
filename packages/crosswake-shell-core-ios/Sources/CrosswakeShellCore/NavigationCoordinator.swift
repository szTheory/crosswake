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
    private let patchSink: (NavigationStackEntry) -> Void
    private var transitionIDs: [String] = []
    private let transitionLedgerLimit = 128

    public init(topology: NavigationTopology, manifest: ShellManifest, resolver: @escaping (String, ShellManifest) -> NavigationResolution, patchSink: @escaping (NavigationStackEntry) -> Void = { _ in }) {
        self.topology = topology; self.manifest = manifest; self.resolver = resolver; self.patchSink = patchSink
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

    /// Applies every accepted web candidate only after manifest/topology validation and
    /// resolver authorization. Rejections deliberately have no observable state effect.
    @discardableResult public func apply(_ transition: NavigationTransition) -> NavigationTransitionOutcome {
        guard topology.validate(against: manifest) == .valid,
              transitionIDs.contains(transition.transitionID) == false,
              let entry = topology.entries.first(where: { $0.routeID == transition.routeID }),
              case let .authorized(presentation) = resolver(transition.routeID, manifest) else { return .denied }

        switch transition.kind {
        case .pushPatch:
            guard activeRouteID == entry.routeID,
                  let tabID = selectedTabID,
                  let current = stacks[tabID]?.last,
                  current.routeID == entry.routeID else { return .denied }
            record(transition.transitionID)
            patchSink(NavigationStackEntry(routeID: entry.routeID, presentation: presentation))
            return .applied
        case .pushNavigate:
            guard entry.presentation == .push,
                  let tabID = selectedTabID,
                  entry.rootTabID == tabID,
                  let current = stacks[tabID]?.last,
                  current.routeID == entry.parentRouteID else { return .denied }
            record(transition.transitionID)
            stacks[tabID, default: []].append(NavigationStackEntry(routeID: entry.routeID, presentation: presentation))
            activeRouteID = entry.routeID
            return .applied
        }
    }

    private func record(_ transitionID: String) {
        transitionIDs.append(transitionID)
        if transitionIDs.count > transitionLedgerLimit { transitionIDs.removeFirst() }
    }
}
