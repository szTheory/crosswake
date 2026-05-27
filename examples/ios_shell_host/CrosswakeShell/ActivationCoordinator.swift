import Foundation
import SwiftUI

enum ActivationSource: String, Codable, Equatable {
    case coldStart = "cold_start"
    case deepLink = "deep_link"
    case notification
    case inAppNavigation = "in_app_navigation"
}

enum ManifestSource: String, Codable, Equatable {
    case bundled
    case cached
    case remote
}

enum RouteDenialReason: String, Codable, Equatable {
    case compatibilityMismatch = "compatibility_mismatch"
    case undeclaredCapability = "undeclared_capability"
    case unavailableCapability = "unavailable_capability"
    case originDenied = "origin_denied"
    case inactiveRoute = "inactive_route"
    case externalEntryDenied = "external_entry_denied"
    case packIncompatible = "pack_incompatible"
}

struct ActivationRequest: Codable, Equatable {
    let routeID: String?
    let url: URL?
    let source: ActivationSource
    let origin: String
    let manifestSource: ManifestSource
    let bridgeProtocolVersion: String
    let nativeRuntimeVersion: String
    let correlationID: String
    let declaredPackRequirements: [String: String]
    let installedPacks: [String: String]
    let capabilities: [String: String]

    enum CodingKeys: String, CodingKey {
        case routeID = "route_id"
        case url
        case source
        case origin
        case manifestSource = "manifest_source"
        case bridgeProtocolVersion = "bridge_protocol_version"
        case nativeRuntimeVersion = "native_runtime_version"
        case correlationID = "correlation_id"
        case declaredPackRequirements = "declared_pack_requirements"
        case installedPacks = "installed_packs"
        case capabilities
    }

    init(
        routeID: String?,
        url: URL?,
        source: ActivationSource,
        origin: String,
        manifestSource: ManifestSource,
        bridgeProtocolVersion: String,
        nativeRuntimeVersion: String,
        correlationID: String,
        declaredPackRequirements: [String: String] = [:],
        installedPacks: [String: String] = [:],
        capabilities: [String: String] = [:]
    ) {
        self.routeID = routeID
        self.url = url
        self.source = source
        self.origin = origin
        self.manifestSource = manifestSource
        self.bridgeProtocolVersion = bridgeProtocolVersion
        self.nativeRuntimeVersion = nativeRuntimeVersion
        self.correlationID = correlationID
        self.declaredPackRequirements = declaredPackRequirements
        self.installedPacks = installedPacks
        self.capabilities = capabilities
    }

    static func forIncomingURL(_ url: URL, source: ActivationSource, seededBy baseline: ActivationRequest) -> ActivationRequest {
        ActivationRequest(
            routeID: nil,
            url: url,
            source: source,
            origin: url.crosswakeOrigin ?? baseline.origin,
            manifestSource: baseline.manifestSource,
            bridgeProtocolVersion: baseline.bridgeProtocolVersion,
            nativeRuntimeVersion: baseline.nativeRuntimeVersion,
            correlationID: baseline.correlationID,
            declaredPackRequirements: baseline.declaredPackRequirements,
            installedPacks: baseline.installedPacks,
            capabilities: baseline.capabilities
        )
    }
}

struct ShellManifest: Codable, Equatable {
    struct TransferSeam: Codable, Equatable {
        let id: String
        let intent: String
        let direction: String
        let source: String?
        let destination: String?
        let verification: String
        let mediaTypes: [String]
        let states: [String]

        enum CodingKeys: String, CodingKey {
            case id
            case intent
            case direction
            case source
            case destination
            case verification
            case mediaTypes = "media_types"
            case states
        }
    }

    struct Route: Codable, Equatable {
        let id: String
        let path: String
        let runtime: String
        let entry: String
        let capabilities: [String]
        let packs: [String]
        let transfers: [TransferSeam]
        let allowlistedOrigins: [String]

        enum CodingKeys: String, CodingKey {
            case id
            case path
            case runtime
            case entry
            case capabilities
            case packs
            case transfers
            case allowlistedOrigins = "allowlisted_origins"
        }
    }

    let routes: [String: Route]
}

enum RouteUnavailableAction: Equatable {
    case retry
    case updateApp
    case safeFallback(URL)
}

struct RouteDenialPresentation: Equatable {
    let reason: RouteDenialReason
    let title: String
    let message: String
    let hint: String?
    let routeID: String?
    let actions: [RouteUnavailableAction]
}

struct LiveViewSession: Equatable {
    let routeID: String
    let url: URL
    let allowedOrigin: URL
    let bridgeProtocolVersion: String
    let nativeRuntimeVersion: String
    let installedPacks: [String: String]
    let routeRequiredPacks: [String]
    let capabilities: [String: String]
    let declaredTransfers: [ShellManifest.TransferSeam]
}

struct RequiredPackPresentation: Equatable {
    let routeID: String
    let runtimeLabel: String
    let status: RequiredPackStatus
}

struct NativeCapturePresentation: Equatable {
    let routeID: String
    let routeTitle: String
    let runtimeLabel: String
    let transferID: String
}

enum ShellPresentation: Equatable {
    case booting
    case requiredPack(RequiredPackPresentation)
    case nativeCapture(NativeCapturePresentation)
    case liveView(LiveViewSession)
    case denied(RouteDenialPresentation)
}

@MainActor
final class ActivationCoordinator: ObservableObject {
    @Published private(set) var presentation: ShellPresentation = .booting
    @Published private(set) var transferCoordinator: TransferCoordinator?

    private let manifestLoader: () throws -> ShellManifest
    private let requestLoader: () throws -> ActivationRequest
    private let packStore: PackStore
    private var hasBootstrapped = false
    private var lastRequest: ActivationRequest?
    private var cachedManifest: ShellManifest?

    init(
        manifestLoader: @escaping () throws -> ShellManifest,
        requestLoader: @escaping () throws -> ActivationRequest,
        packStore: PackStore
    ) {
        self.manifestLoader = manifestLoader
        self.requestLoader = requestLoader
        self.packStore = packStore
    }

    static func bundled(bundle: Bundle = .main) -> ActivationCoordinator {
        let store = (try? PackStore.bundled(bundle: bundle)) ?? PackStore(requiredVersions: [:], inventory: [])

        return ActivationCoordinator(
            manifestLoader: { try Self.decode("crosswake_manifest", bundle: bundle) },
            requestLoader: { try Self.decode("route_activation", bundle: bundle) },
            packStore: store
        )
    }

    func bootstrapIfNeeded() {
        guard hasBootstrapped == false else { return }
        hasBootstrapped = true

        do {
            let request = try requestLoader()
            activate(request)
        } catch {
            presentation = .denied(
                RouteDenialPresentation(
                    reason: .compatibilityMismatch,
                    title: "Shell boot blocked",
                    message: "The bundled manifest truth could not be loaded before runtime mount.",
                    hint: error.localizedDescription,
                    routeID: nil,
                    actions: [.retry]
                )
            )
        }
    }

    func openURL(_ url: URL) {
        handleIncomingURL(url, source: .deepLink)
    }

    func continueUserActivity(_ userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        handleIncomingURL(url, source: .deepLink)
    }

    func perform(_ action: RouteUnavailableAction) {
        switch action {
        case .retry:
            if let lastRequest {
                activate(lastRequest)
            } else {
                bootstrapIfNeeded()
            }
        case .updateApp:
            break
        case let .safeFallback(url):
            handleIncomingURL(url, source: .inAppNavigation)
        }
    }

    func presentNavigationDenial(_ denial: RouteDenialPresentation) {
        presentation = .denied(denial)
    }

    func installRequiredPack(_ requiredPack: RequiredPackPresentation) async {
        await packStore.installRequiredPack(requiredPack.status)
        reactivateLastRequest()
    }

    func retryRequiredPack(_ requiredPack: RequiredPackPresentation) async {
        await packStore.retry(requiredPack.status)
        reactivateLastRequest()
    }

    func invalidateRequiredPack(_ requiredPack: RequiredPackPresentation) async {
        await packStore.invalidatePack(requiredPack.status)
        reactivateLastRequest()
    }

    func activate(_ request: ActivationRequest) {
        do {
            let manifest = try loadManifest()
            lastRequest = request
            presentation = resolve(request: request, manifest: manifest)
        } catch {
            presentation = .denied(
                RouteDenialPresentation(
                    reason: .compatibilityMismatch,
                    title: "Shell boot blocked",
                    message: "The bundled manifest truth could not be loaded before runtime mount.",
                    hint: error.localizedDescription,
                    routeID: request.routeID,
                    actions: [.retry]
                )
            )
        }
    }

    func resolve(request: ActivationRequest, manifest: ShellManifest) -> ShellPresentation {
        guard let route = route(for: request, manifest: manifest) else {
            return .denied(
                denial(
                    reason: .inactiveRoute,
                    routeID: request.routeID,
                    manifest: manifest,
                    message: "This route is not active in the bundled manifest.",
                    hint: "Retry after shipping an updated shell manifest."
                )
            )
        }

        if externalActivationSource(request.source) && route.entry != "external" {
            return .denied(
                denial(
                    reason: .externalEntryDenied,
                    routeID: route.id,
                    manifest: manifest,
                    message: "This route exists in the manifest but does not allow external entry.",
                    hint: "Declare external entry for the route before opening it from a deep link."
                )
            )
        }

        if let blockingPack = packStore.blockingStatus(for: route.packs) {
            transferCoordinator = nil
            return .requiredPack(
                RequiredPackPresentation(
                    routeID: route.id,
                    runtimeLabel: "LiveView",
                    status: blockingPack
                )
            )
        }

        if route.runtime == "native_screen" {
            let routeTransferCoordinator = TransferCoordinator(routeID: route.id, declaredTransfers: route.transfers)
            transferCoordinator = routeTransferCoordinator

            guard let transferID = captureTransferID(for: route) else {
                return .denied(
                    denial(
                        reason: .compatibilityMismatch,
                        routeID: route.id,
                        manifest: manifest,
                        message: "This native capture route is missing its declared transfer handoff.",
                        hint: "Ship the route with a manifest-declared native capture upload seam before opening it."
                    )
                )
            }

            return .nativeCapture(
                NativeCapturePresentation(
                    routeID: route.id,
                    routeTitle: routeTitle(for: route),
                    runtimeLabel: "Native capture",
                    transferID: transferID
                )
            )
        }

        guard route.runtime == "live_view" else {
            transferCoordinator = nil
            return .denied(
                denial(
                    reason: .compatibilityMismatch,
                    routeID: route.id,
                    manifest: manifest,
                    message: "This runtime is not available in the bounded shell.",
                    hint: "Open the declared native capture route instead of falling back into the bounded web container."
                )
            )
        }

        guard route.allowlistedOrigins.contains(request.origin) else {
            return .denied(
                denial(
                    reason: .originDenied,
                    routeID: route.id,
                    manifest: manifest,
                    message: "The requested origin is not allowlisted for this route.",
                    hint: "Open a declared safe fallback route or retry from a trusted origin."
                )
            )
        }

        let resolvedURL = request.url ?? URL(string: request.origin + route.path)!
        let allowedOrigin = URL(string: request.origin) ?? resolvedURL
        let routeTransferCoordinator = route.transfers.isEmpty
            ? nil
            : TransferCoordinator(routeID: route.id, declaredTransfers: route.transfers)

        transferCoordinator = routeTransferCoordinator

        return .liveView(
            LiveViewSession(
                routeID: route.id,
                url: resolvedURL,
                allowedOrigin: allowedOrigin,
                bridgeProtocolVersion: request.bridgeProtocolVersion,
                nativeRuntimeVersion: request.nativeRuntimeVersion,
                installedPacks: request.installedPacks,
                routeRequiredPacks: route.packs,
                capabilities: request.capabilities,
                declaredTransfers: route.transfers
            )
        )
    }

    private func handleIncomingURL(_ url: URL, source: ActivationSource) {
        do {
            let seededRequest = try requestLoader()
            activate(.forIncomingURL(url, source: source, seededBy: seededRequest))
        } catch {
            presentation = .denied(
                RouteDenialPresentation(
                    reason: .compatibilityMismatch,
                    title: "Shell boot blocked",
                    message: "The shell could not load its activation contract.",
                    hint: error.localizedDescription,
                    routeID: nil,
                    actions: [.retry]
                )
            )
        }
    }

    private func loadManifest() throws -> ShellManifest {
        if let cachedManifest {
            return cachedManifest
        }

        let manifest = try manifestLoader()
        cachedManifest = manifest
        return manifest
    }

    private func route(for request: ActivationRequest, manifest: ShellManifest) -> ShellManifest.Route? {
        if let routeID = request.routeID, let route = manifest.routes[routeID] {
            return route
        }

        guard let path = request.url?.path else { return nil }

        return manifest.routes.values.first(where: { routePathMatches(routePath: $0.path, requestPath: path) })
    }

    private func routePathMatches(routePath: String, requestPath: String) -> Bool {
        let routeSegments = routePath.split(separator: "/").map(String.init)
        let requestSegments = requestPath.split(separator: "/").map(String.init)

        guard routeSegments.count == requestSegments.count else { return false }

        return zip(routeSegments, requestSegments).allSatisfy { routeSegment, requestSegment in
            routeSegment.hasPrefix(":") || routeSegment == requestSegment
        }
    }

    private func requiredPacks(for route: ShellManifest.Route) -> [String: String] {
        route.packs.reduce(into: [:]) { result, pack in
            let components = pack.split(separator: "@", maxSplits: 1).map(String.init)
            guard components.count == 2 else { return }
            result[components[0]] = components[1]
        }
    }

    private func captureTransferID(for route: ShellManifest.Route) -> String? {
        route.transfers.first(where: { $0.intent == "upload" && $0.source == "native_capture" })?.id
    }

    private func routeTitle(for route: ShellManifest.Route) -> String {
        route.id
            .split(separator: "-", omittingEmptySubsequences: true)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    private func reactivateLastRequest() {
        guard let lastRequest else { return }
        activate(lastRequest)
    }

    private func denial(
        reason: RouteDenialReason,
        routeID: String?,
        manifest: ShellManifest,
        message: String,
        hint: String?,
        actions: [RouteUnavailableAction] = [.retry]
    ) -> RouteDenialPresentation {
        var recovery = actions

        if recovery.contains(where: { if case .safeFallback = $0 { return true }; return false }) == false,
           let fallbackURL = fallbackURL(manifest: manifest) {
            recovery.append(.safeFallback(fallbackURL))
        }

        return RouteDenialPresentation(
            reason: reason,
            title: "Route unavailable",
            message: message,
            hint: hint,
            routeID: routeID,
            actions: recovery
        )
    }

    private func fallbackURL(manifest: ShellManifest) -> URL? {
        guard let route = manifest.routes.values.first(where: { $0.runtime == "live_view" }),
              let origin = route.allowlistedOrigins.first else {
            return nil
        }

        return URL(string: origin + route.path)
    }

    private func externalActivationSource(_ source: ActivationSource) -> Bool {
        source == .deepLink || source == .notification
    }

    private static func decode<T: Decodable>(_ name: String, bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

extension URL {
    var crosswakeOrigin: String? {
        guard let scheme, let host else { return nil }

        if let port, port != defaultPortForScheme {
            return "\(scheme)://\(host):\(port)"
        }

        return "\(scheme)://\(host)"
    }

    var defaultPortForScheme: Int? {
        switch scheme {
        case "https":
            return 443
        case "http":
            return 80
        default:
            return nil
        }
    }
}
