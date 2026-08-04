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

    /// The only roots a host shell may materialize. An unvalidated or blocked topology
    /// deliberately produces no native chrome.
    public var rootRouteIDs: [String] {
        guard topology.validate(against: manifest) == .valid else { return [] }
        return topology.entries.compactMap { $0.presentation == .root ? $0.routeID : nil }
    }

    public var hasPromotableTopology: Bool { rootRouteIDs.isEmpty == false }

    public init(topology: NavigationTopology, manifest: ShellManifest, resolver: @escaping (String, ShellManifest) -> NavigationResolution, patchSink: @escaping (NavigationStackEntry) -> Void = { _ in }) {
        self.topology = topology; self.manifest = manifest; self.resolver = resolver; self.patchSink = patchSink
    }

    @discardableResult public func selectRoot(routeID: String) -> NavigationSelectionResult {
        guard topology.validate(against: manifest) == .valid,
              let entry = topology.entries.first(where: { $0.routeID == routeID && $0.presentation == .root }),
              case let .authorized(presentation) = resolver(routeID, manifest) else { return .denied }
        selectedTabID = entry.rootTabID
        if let retained = stacks[entry.rootTabID], let leaf = retained.last {
            activeRouteID = leaf.routeID
        } else {
            let stackEntry = NavigationStackEntry(routeID: entry.routeID, presentation: presentation)
            stacks[entry.rootTabID] = [stackEntry]
            activeRouteID = entry.routeID
        }
        return .authorized
    }

    /// A canceled interactive edge swipe is intentionally a no-op. A completed pop
    /// resolves the destination before replacing the retained stack.
    @discardableResult public func completeNativePop(completed: Bool) -> NavigationSelectionResult {
        guard completed,
              let tabID = selectedTabID,
              let stack = stacks[tabID], stack.count > 1,
              let destination = stack.dropLast().last,
              case .authorized = resolver(destination.routeID, manifest) else { return .denied }
        stacks[tabID] = Array(stack.dropLast())
        activeRouteID = destination.routeID
        return .authorized
    }

    @discardableResult public func reconstructDeepLink(routeIDs: [String]) -> NavigationSelectionResult {
        reconstruct(routeIDs: routeIDs, posture: \.deepLinkPosture)
    }

    @discardableResult public func reconstructRestoration(routeIDs: [String]) -> NavigationSelectionResult {
        reconstruct(routeIDs: routeIDs, posture: \.restorationPosture)
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

    private func reconstruct(routeIDs: [String], posture: KeyPath<NavigationTopologyEntry, NavigationEntryPosture>) -> NavigationSelectionResult {
        guard topology.validate(against: manifest) == .valid, routeIDs.isEmpty == false else { return .denied }
        let candidates = routeIDs.compactMap { routeID in topology.entries.first(where: { $0.routeID == routeID }) }
        guard candidates.count == routeIDs.count,
              candidates.allSatisfy({ $0[keyPath: posture] == .allow }),
              candidates.first?.presentation == .root,
              candidates.dropFirst().enumerated().allSatisfy({ index, entry in entry.presentation == .push && entry.parentRouteID == candidates[index].routeID }) else { return .denied }

        var staged: [NavigationStackEntry] = []
        for candidate in candidates {
            guard case let .authorized(presentation) = resolver(candidate.routeID, manifest) else { return .denied }
            staged.append(NavigationStackEntry(routeID: candidate.routeID, presentation: presentation))
        }
        guard let tabID = candidates.first?.rootTabID else { return .denied }
        selectedTabID = tabID
        stacks[tabID] = staged
        activeRouteID = staged.last?.routeID
        return .authorized
    }
}
