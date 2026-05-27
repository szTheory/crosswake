package dev.crosswake.shell

import dev.crosswake.shell.packs.PackStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ActivationCoordinatorTest {
    @Test
    fun bootstrapAllowsBundledLiveViewRoute() {
        val coordinator = coordinator()

        val presentation = coordinator.activate(baselineRequest())

        assertTrue(presentation is ShellPresentation.LiveView)
        assertEquals("library", (presentation as ShellPresentation.LiveView).session.routeId)
    }

    @Test
    fun stalePackInventoryShowsRequiredPackSurface() {
        val presentation = staleCoordinator().activate(baselineRequest())

        assertTrue(presentation is ShellPresentation.RequiredPack)
        val requiredPack = (presentation as ShellPresentation.RequiredPack).requiredPack
        assertEquals("library", requiredPack.routeId)
        assertEquals("1.1.0", requiredPack.status.installedVersion)
        assertEquals("stale", requiredPack.status.state.wireValue)
    }

    @Test
    fun inAppNavigationDeniesDisallowedOriginAndKeepsCurrentRouteStable() {
        val coordinator = coordinator()
        coordinator.activate(baselineRequest())

        val decision = coordinator.resolveNavigation("https://evil.example.com/dashboard")

        assertTrue(decision is NavigationDecision.Deny)
        assertEquals(
            RouteDenialReason.ORIGIN_DENIED,
            (decision as NavigationDecision.Deny).denial.reason
        )
        assertEquals("library", coordinator.currentSession?.routeId)
    }

    @Test
    fun appLinkToUnknownRouteFailsClosed() {
        val coordinator = coordinator()

        val presentation = coordinator.activate(
            ActivationRequest.forIncomingUrl(
                "https://example.crosswake.invalid/missing",
                ActivationSource.DEEP_LINK,
                baselineRequest()
            )
        )

        assertTrue(presentation is ShellPresentation.Denied)
        assertEquals(
            RouteDenialReason.INACTIVE_ROUTE,
            (presentation as ShellPresentation.Denied).denial.reason
        )
    }

    @Test
    fun appLinkToKnownInternalRouteUsesExternalEntryDeniedReason() {
        val coordinator = coordinator()

        val presentation = coordinator.activate(
            ActivationRequest.forIncomingUrl(
                "https://example.crosswake.invalid/study/session",
                ActivationSource.DEEP_LINK,
                baselineRequest()
            )
        )

        assertTrue(presentation is ShellPresentation.Denied)
        assertEquals(
            RouteDenialReason.EXTERNAL_ENTRY_DENIED,
            (presentation as ShellPresentation.Denied).denial.reason
        )
    }

    @Test
    fun dynamicSegmentRoutesMatchDeepLinksConsistently() {
        val coordinator = coordinator(dynamicRequest())

        val presentation = coordinator.activate(
            ActivationRequest.forIncomingUrl(
                "https://example.crosswake.invalid/native/claims/claim-1/capture",
                ActivationSource.DEEP_LINK,
                dynamicRequest()
            )
        )

        assertTrue(presentation is ShellPresentation.NativeCapture)
        assertEquals(
            "selective-native-claim-capture",
            (presentation as ShellPresentation.NativeCapture).nativeCapture.routeId
        )
    }

    private fun coordinator(request: ActivationRequest = baselineRequest()): ActivationCoordinator {
        return ActivationCoordinator(
            manifestLoader = { manifest() },
            requestLoader = { request },
            packStore = PackStore.inMemory(
                requiredVersions = mapOf(
                    "lesson_library" to "1.2.0",
                    "camera_capture_assets" to "1.0.0"
                ),
                inventory = listOf(
                    packInventoryRecord("lesson_library", "1.2.0", "1.2.0"),
                    packInventoryRecord("camera_capture_assets", "1.0.0", "1.0.0")
                )
            )
        )
    }

    private fun staleCoordinator(request: ActivationRequest = baselineRequest()): ActivationCoordinator {
        return ActivationCoordinator(
            manifestLoader = { manifest() },
            requestLoader = { request },
            packStore = PackStore.inMemory(
                requiredVersions = mapOf(
                    "lesson_library" to "1.2.0",
                    "camera_capture_assets" to "1.0.0"
                ),
                inventory = listOf(
                    packInventoryRecord("lesson_library", "1.2.0", "1.1.0"),
                    packInventoryRecord("camera_capture_assets", "1.0.0", "1.0.0")
                )
            )
        )
    }

    private fun manifest(): ShellManifest {
        return ShellManifest(
            routes = mapOf(
                "dashboard" to ShellManifest.Route(
                    id = "library",
                    path = "/library",
                    runtime = "live_view",
                    entry = "internal_only",
                    capabilities = emptyList(),
                    packs = listOf("lesson_library@1.2.0"),
                    transfers = listOf(
                        ShellManifest.TransferSeam(
                            id = "lesson_import",
                            intent = "import",
                            direction = "inbound",
                            source = "native_picker",
                            destination = null,
                            verification = "required",
                            mediaTypes = listOf("application/pdf"),
                            states = listOf(
                                "queued",
                                "preparing",
                                "transferring",
                                "awaiting_network",
                                "verifying",
                                "complete",
                                "failed",
                                "canceled"
                            )
                        )
                    ),
                    allowlistedOrigins = listOf("https://example.crosswake.invalid")
                ),
                "study-session" to ShellManifest.Route(
                    id = "study-session",
                    path = "/study/session",
                    runtime = "offline_island",
                    entry = "internal_only",
                    capabilities = emptyList(),
                    packs = emptyList(),
                    transfers = emptyList(),
                    allowlistedOrigins = listOf("https://example.crosswake.invalid")
                ),
                "selective-native-claim-capture" to ShellManifest.Route(
                    id = "selective-native-claim-capture",
                    path = "/native/claims/:id/capture",
                    runtime = "native_screen",
                    entry = "external",
                    capabilities = emptyList(),
                    packs = listOf("camera_capture_assets@1.0.0"),
                    transfers = listOf(
                        ShellManifest.TransferSeam(
                            id = "capture_upload",
                            intent = "upload",
                            direction = "outbound",
                            source = "native_capture",
                            destination = null,
                            verification = "required",
                            mediaTypes = emptyList(),
                            states = emptyList()
                        )
                    ),
                    allowlistedOrigins = listOf("https://example.crosswake.invalid")
                )
            )
        )
    }

    private fun baselineRequest(): ActivationRequest {
        return ActivationRequest(
            routeId = "library",
            url = "https://example.crosswake.invalid/library",
            source = ActivationSource.DEEP_LINK,
            origin = "https://example.crosswake.invalid",
            manifestSource = ManifestSource.BUNDLED,
            bridgeProtocolVersion = "1.0.0",
            nativeRuntimeVersion = "1.0.0",
            correlationId = "android-example-library-1",
            declaredPackRequirements = mapOf("lesson_library" to "1.2.0"),
            installedPacks = mapOf("lesson_library" to "1.2.0", "camera_capture_assets" to "1.0.0"),
            capabilities = emptyMap()
        )
    }

    private fun dynamicRequest(): ActivationRequest {
        return ActivationRequest(
            routeId = "selective-native-claim-capture",
            url = "https://example.crosswake.invalid/native/claims/claim-1/capture",
            source = ActivationSource.DEEP_LINK,
            origin = "https://example.crosswake.invalid",
            manifestSource = ManifestSource.BUNDLED,
            bridgeProtocolVersion = "1.0.0",
            nativeRuntimeVersion = "1.0.0",
            correlationId = "android-example-capture-1",
            declaredPackRequirements = mapOf("camera_capture_assets" to "1.0.0"),
            installedPacks = mapOf("lesson_library" to "1.2.0", "camera_capture_assets" to "1.0.0"),
            capabilities = emptyMap()
        )
    }

    private fun packInventoryRecord(
        packId: String,
        requiredVersion: String,
        installedVersion: String
    ): dev.crosswake.shell.packs.PackInventoryRecord {
        return dev.crosswake.shell.packs.PackInventoryRecord(
            packId = packId,
            requiredVersion = requiredVersion,
            installedVersion = installedVersion,
            bytes = 24_576,
            integrityStatus = "verified",
            verifiedAt = "2026-05-17T09:00:00Z",
            status = "available"
        )
    }
}
