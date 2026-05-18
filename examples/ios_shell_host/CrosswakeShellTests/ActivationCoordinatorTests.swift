import Foundation
import XCTest
@testable import CrosswakeShell

@MainActor
final class ActivationCoordinatorTests: XCTestCase {
    func testBundledLaunchAllowsLiveViewRouteBeforeRuntimeMount() {
        let coordinator = ActivationCoordinator(
            manifestLoader: { Self.manifest },
            requestLoader: { Self.allowedRequest },
            packStore: Self.packStore
        )

        coordinator.bootstrapIfNeeded()

        guard case let .liveView(session) = coordinator.presentation else {
            return XCTFail("expected live view presentation")
        }

        XCTAssertEqual(session.routeID, "selective-native-claim-capture")
        XCTAssertEqual(session.url.absoluteString, "https://example.crosswake.invalid/native/claims/claim-1/capture")
        XCTAssertEqual(session.capabilities["camera"], "1.0.0")
    }

    func testDeniedDeepLinkUsesExplicitInactiveRouteSurface() {
        let coordinator = ActivationCoordinator(
            manifestLoader: { Self.manifest },
            requestLoader: { Self.allowedRequest },
            packStore: Self.packStore
        )

        coordinator.openURL(URL(string: "https://example.com/missing")!)

        guard case let .denied(denial) = coordinator.presentation else {
            return XCTFail("expected denial presentation")
        }

        XCTAssertEqual(denial.reason, RouteDenialReason.inactiveRoute)
        XCTAssertTrue(denial.actions.contains(RouteUnavailableAction.retry))
    }

    func testStalePackInventoryShowsRequiredPackSurface() {
        let coordinator = ActivationCoordinator(
            manifestLoader: { Self.manifest },
            requestLoader: { Self.libraryPackRequest },
            packStore: Self.stalePackStore
        )

        coordinator.bootstrapIfNeeded()

        guard case let .requiredPack(requiredPack) = coordinator.presentation else {
            return XCTFail("expected required pack presentation")
        }

        XCTAssertEqual(requiredPack.routeID, "library")
        XCTAssertEqual(requiredPack.status.state, .stale)
        XCTAssertEqual(requiredPack.status.installedVersion, "1.1.0")
    }

    func testInAppNavigationDeniesDisallowedOrigin() {
        let coordinator = ActivationCoordinator(
            manifestLoader: { Self.manifest },
            requestLoader: { Self.allowedRequest },
            packStore: Self.packStore
        )

        coordinator.activate(
            ActivationRequest(
                routeID: "library",
                url: URL(string: "https://evil.example/dashboard"),
                source: .inAppNavigation,
                origin: "https://evil.example",
                manifestSource: .bundled,
                bridgeProtocolVersion: "1.0.0",
                nativeRuntimeVersion: "1.0.0",
                correlationID: "ios-nav-1",
                declaredPackRequirements: ["lesson_library": "1.2.0"],
                installedPacks: ["lesson_library": "1.2.0", "camera_capture_assets": "1.0.0"],
                capabilities: [:]
            )
        )

        guard case let .denied(denial) = coordinator.presentation else {
            return XCTFail("expected denial presentation")
        }

        XCTAssertEqual(denial.reason, RouteDenialReason.originDenied)
        XCTAssertTrue(denial.actions.contains(RouteUnavailableAction.retry))
    }

    func testLiveViewContainerAllowsSameOriginNavigation() {
        XCTAssertTrue(
            LiveViewContainerViewController.isNavigationAllowed(
                URL(string: "https://example.com/dashboard?tab=1")!,
                allowedOrigin: URL(string: "https://example.com")!
            )
        )
    }

    func testLiveViewContainerDeniesDisallowedOriginNavigation() {
        XCTAssertFalse(
            LiveViewContainerViewController.isNavigationAllowed(
                URL(string: "https://evil.example/dashboard")!,
                allowedOrigin: URL(string: "https://example.com")!
            )
        )
    }

    private static let manifest = ShellManifest(
        routes: [
            "library": .init(
                id: "library",
                path: "/library",
                runtime: "live_view",
                capabilities: [],
                packs: ["lesson_library@1.2.0"],
                transfers: [
                    .init(
                        id: "lesson_import",
                        intent: "import",
                        direction: "inbound",
                        source: "native_picker",
                        destination: nil,
                        verification: "required",
                        mediaTypes: ["application/pdf"],
                        states: [
                            "queued",
                            "preparing",
                            "transferring",
                            "awaiting_network",
                            "verifying",
                            "complete",
                            "failed",
                            "canceled"
                        ]
                    )
                ],
                allowlistedOrigins: ["https://example.crosswake.invalid"]
            ),
            "selective-native-claim-capture": .init(
                id: "selective-native-claim-capture",
                path: "/native/claims/:id/capture",
                runtime: "native_screen",
                capabilities: ["camera"],
                packs: ["camera_capture_assets@1.0.0"],
                transfers: [
                    .init(
                        id: "capture_upload",
                        intent: .upload,
                        source: .nativeCapture,
                        verification: .required,
                        mediaTypes: ["image/*"]
                    )
                ],
                allowlistedOrigins: ["https://example.com"]
            )
            ]
            )

            private static let allowedRequest = ActivationRequest(
            routeID: "selective-native-claim-capture",
            url: URL(string: "https://example.crosswake.invalid/native/claims/claim-1/capture"),
            source: .coldStart,
            origin: "https://example.crosswake.invalid",
            manifestSource: .bundled,
            bridgeProtocolVersion: "1.0.0",
            nativeRuntimeVersion: "1.0.0",
            correlationID: "ios-example-capture-1",
            declaredPackRequirements: ["camera_capture_assets": "1.0.0"],
            installedPacks: ["camera_capture_assets": "1.0.0"],
            capabilities: ["camera": "1.0.0"]
    )

    private static let libraryPackRequest = ActivationRequest(
        routeID: "library",
        url: URL(string: "https://example.crosswake.invalid/library"),
        source: .coldStart,
        origin: "https://example.crosswake.invalid",
        manifestSource: .bundled,
        bridgeProtocolVersion: "1.0.0",
        nativeRuntimeVersion: "1.0.0",
        correlationID: "ios-example-library-1",
        declaredPackRequirements: ["lesson_library": "1.2.0"],
        installedPacks: ["lesson_library": "1.2.0", "camera_capture_assets": "1.0.0"],
        capabilities: [:]
    )

    private static let packStore = PackStore(
        requiredVersions: [
            "lesson_library": "1.2.0",
            "camera_capture_assets": "1.0.0"
        ],
        inventory: [
            PackInventoryRecord(
                packID: "lesson_library",
                requiredVersion: "1.2.0",
                installedVersion: "1.2.0",
                bytes: 24_576,
                integrityStatus: "verified",
                verifiedAt: ISO8601DateFormatter().date(from: "2026-05-17T09:00:00Z"),
                status: "available"
            ),
            PackInventoryRecord(
                packID: "camera_capture_assets",
                requiredVersion: "1.0.0",
                installedVersion: "1.0.0",
                bytes: 12_288,
                integrityStatus: "verified",
                verifiedAt: ISO8601DateFormatter().date(from: "2026-05-17T09:00:00Z"),
                status: "available"
            )
        ]
    )

    private static let stalePackStore = PackStore(
        requiredVersions: [
            "lesson_library": "1.2.0",
            "camera_capture_assets": "1.0.0"
        ],
        inventory: [
            PackInventoryRecord(
                packID: "lesson_library",
                requiredVersion: "1.2.0",
                installedVersion: "1.1.0",
                bytes: 24_576,
                integrityStatus: "verified",
                verifiedAt: ISO8601DateFormatter().date(from: "2026-05-17T09:00:00Z"),
                status: "available"
            ),
            PackInventoryRecord(
                packID: "camera_capture_assets",
                requiredVersion: "1.0.0",
                installedVersion: "1.0.0",
                bytes: 12_288,
                integrityStatus: "verified",
                verifiedAt: ISO8601DateFormatter().date(from: "2026-05-17T09:00:00Z"),
                status: "available"
            )
        ]
    )
}
