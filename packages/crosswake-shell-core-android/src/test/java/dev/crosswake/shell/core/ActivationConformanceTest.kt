package dev.crosswake.shell.core

import dev.crosswake.shell.core.packs.PackInventoryRecord
import dev.crosswake.shell.core.packs.PackStore
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class ActivationConformanceTest {

    private lateinit var bridgeProtocolVersion: String
    private lateinit var nativeRuntimeVersion: String

    @Before
    fun loadVectors() {
        // Version-anchor to the committed vectors file per D-01.
        // A bridge protocol version bump regenerates this file, flowing through here.
        val text = javaClass.getResourceAsStream("/bridge_contract_vectors.json")!!
            .bufferedReader().readText()
        val json = JSONObject(text)
        bridgeProtocolVersion = json.getString("bridge_protocol_version")
        nativeRuntimeVersion = json.getString("native_runtime_version")
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private fun makeManifest(
        routeId: String = "dashboard",
        runtime: String = "live_view",
        entry: String = "internal_only",
        packs: List<String> = emptyList(),
        allowlistedOrigins: List<String> = listOf("https://app.example.com")
    ) = ShellManifest(
        routes = mapOf(
            routeId to ShellManifest.Route(
                id = routeId,
                path = "/$routeId",
                runtime = runtime,
                entry = entry,
                capabilities = emptyList(),
                packs = packs,
                transfers = emptyList(),
                allowlistedOrigins = allowlistedOrigins
            )
        ),
        nativeRuntimeVersion = nativeRuntimeVersion
    )

    private fun makeRequest(
        routeId: String = "dashboard",
        source: ActivationSource = ActivationSource.COLD_START,
        origin: String = "https://app.example.com",
        reqNativeRuntimeVersion: String = nativeRuntimeVersion
    ) = ActivationRequest(
        routeId = routeId,
        url = null,
        source = source,
        origin = origin,
        manifestSource = ManifestSource.BUNDLED,
        bridgeProtocolVersion = bridgeProtocolVersion,
        nativeRuntimeVersion = reqNativeRuntimeVersion,
        correlationId = "test-correlation-id"
    )

    private fun makeCoordinator(
        manifest: ShellManifest,
        request: ActivationRequest,
        packStore: PackStore = PackStore.inMemory(emptyMap())
    ) = ActivationCoordinator(
        config = CrosswakeShellConfig(),
        manifestLoader = { manifest },
        requestLoader = { request },
        packStore = packStore
    )

    // ── Activation success ────────────────────────────────────────────────

    @Test
    fun `activation resolves live_view route to LiveView presentation`() {
        val manifest = makeManifest()
        val request = makeRequest()
        val coordinator = makeCoordinator(manifest, request)

        val result = coordinator.activate(request)

        assertTrue("Expected LiveView but got $result", result is ShellPresentation.LiveView)
        val session = (result as ShellPresentation.LiveView).session
        assertEquals("dashboard", session.routeId)
        // Version is anchored to the vectors file via bridgeProtocolVersion loaded in @Before
        assertEquals(bridgeProtocolVersion, session.bridgeProtocolVersion)
    }

    // ── Activation denial: inactive route ────────────────────────────────

    @Test
    fun `activation denies unknown route with inactive_route reason`() {
        val manifest = makeManifest(routeId = "dashboard")
        val request = makeRequest(routeId = "ghost-route")
        val coordinator = makeCoordinator(manifest, request)

        val result = coordinator.activate(request)

        assertTrue("Expected Denied but got $result", result is ShellPresentation.Denied)
        assertEquals(
            RouteDenialReason.INACTIVE_ROUTE,
            (result as ShellPresentation.Denied).denial.reason
        )
    }

    // ── Activation denial: required pack not installed ────────────────────

    @Test
    fun `activation blocks activation when required pack is not installed`() {
        val manifest = makeManifest(packs = listOf("test-pack@1.0.0"))
        val request = makeRequest()
        // PackStore.inMemory needs the pack pre-seeded so blockingStatus() finds it in memoryStatuses
        // without touching SharedPreferences (which requires an Android context).
        // An inventory record with integrityStatus != "verified" produces FAILED state (not AVAILABLE),
        // which causes blockingStatus to return a non-null result → RequiredPack presentation.
        val packStore = PackStore.inMemory(
            requiredVersions = mapOf("test-pack" to "1.0.0"),
            inventory = listOf(
                PackInventoryRecord(
                    packId = "test-pack",
                    requiredVersion = "1.0.0",
                    installedVersion = "1.0.0",
                    bytes = 0L,
                    integrityStatus = "unverified",
                    verifiedAt = null,
                    status = "available"
                )
            )
        )
        val coordinator = makeCoordinator(manifest, request, packStore)

        val result = coordinator.activate(request)

        assertTrue("Expected RequiredPack but got $result", result is ShellPresentation.RequiredPack)
        val requiredPack = (result as ShellPresentation.RequiredPack).requiredPack
        assertEquals("test-pack", requiredPack.status.packId)
    }
}
