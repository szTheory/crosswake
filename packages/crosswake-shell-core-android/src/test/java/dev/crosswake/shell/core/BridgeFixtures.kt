package dev.crosswake.shell.core

import org.json.JSONObject

/**
 * Shared JVM test fixtures for the bridge boundary tests. These are copies of the
 * helpers in BridgeConformanceTest (which keeps its own), not a move.
 */
internal object BridgeFixtures {

    fun bridgeVersion(): String {
        val stream = BridgeFixtures::class.java.getResourceAsStream("/bridge_contract_vectors.json")
            ?: throw AssertionError("CW-VECTOR-MISSING bridge_contract_vectors.json")
        val text = stream.bufferedReader().use { it.readText() }
        return JSONObject(text).getString("bridge_protocol_version")
    }

    fun makeSession(
        bridgeProtocolVersion: String = bridgeVersion(),
        nativeRuntimeVersion: String = "1.0.0",
        routeId: String = "dashboard",
        allowedOrigin: String = "https://app.example.com",
        capabilities: Map<String, String> = emptyMap(),
        installedPacks: Map<String, String> = emptyMap(),
        routeRequiredPacks: List<String> = emptyList()
    ) = LiveViewSession(
        routeId = routeId,
        url = "https://app.example.com/dashboard",
        allowedOrigin = allowedOrigin,
        bridgeProtocolVersion = bridgeProtocolVersion,
        nativeRuntimeVersion = nativeRuntimeVersion,
        threadId = "test-thread-id",
        installedPacks = installedPacks,
        routeRequiredPacks = routeRequiredPacks,
        capabilities = capabilities,
        declaredTransfers = emptyList()
    )

    fun makeRequest(
        command: String = "app.info.get",
        capability: String = "app.info.get",
        version: String = bridgeVersion(),
        nativeRuntimeVersion: String = "1.0.0",
        routeId: String = "dashboard",
        activeRouteId: String = "dashboard",
        origin: String = "https://app.example.com",
        capabilities: Map<String, String> = mapOf("app.info.get" to "1.0.0"),
        installedPacks: Map<String, String> = emptyMap()
    ) = BridgeRequestEnvelope(
        protocol = "crosswake.bridge",
        version = version,
        command = command,
        capability = capability,
        routeId = routeId,
        activeRouteId = activeRouteId,
        origin = origin,
        nativeRuntimeVersion = nativeRuntimeVersion,
        correlationId = "test-correlation-id",
        capabilities = capabilities,
        installedPacks = installedPacks,
        payload = emptyMap()
    )

    /** The wire commands listed in the shared vector corpus `commands` array. */
    fun vectorCommands(): Set<String> {
        val stream = BridgeFixtures::class.java.getResourceAsStream("/bridge_contract_vectors.json")
            ?: throw AssertionError("CW-VECTOR-MISSING bridge_contract_vectors.json")
        val text = stream.bufferedReader().use { it.readText() }
        val array = JSONObject(text).getJSONArray("commands")
        return (0 until array.length()).map { array.getString(it) }.toSet()
    }

    /** The reply's top-level `status` (`ok` or `deny`). */
    fun status(reply: String): String = JSONObject(reply).getString("status")

    /** The reply's `denial.denial.reason`; fails the test if the reply is not a denial. */
    fun denialReason(reply: String): String =
        JSONObject(reply).getJSONObject("denial").getJSONObject("denial").getString("reason")

    val REQUIRED_STRING_FIELDS = listOf(
        "protocol",
        "version",
        "command",
        "capability",
        "route_id",
        "active_route_id",
        "origin",
        "native_runtime_version",
        "correlation_id"
    )

    /** A valid request body consistent with [makeSession] defaults. */
    fun validEnvelopeJson(): JSONObject = JSONObject()
        .put("protocol", "crosswake.bridge")
        .put("version", bridgeVersion())
        .put("command", "app.info.get")
        .put("capability", "app.info.get")
        .put("route_id", "dashboard")
        .put("active_route_id", "dashboard")
        .put("origin", "https://app.example.com")
        .put("native_runtime_version", "1.0.0")
        .put("correlation_id", "test-correlation-id")
        .put("capabilities", JSONObject())
        .put("installed_packs", JSONObject())
        .put("payload", JSONObject())
}
