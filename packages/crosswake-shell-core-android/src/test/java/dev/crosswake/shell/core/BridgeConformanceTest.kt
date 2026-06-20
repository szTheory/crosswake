package dev.crosswake.shell.core

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class BridgeConformanceTest {

    private lateinit var vectorsJson: JSONObject
    private lateinit var bridgeVersion: String

    @Before
    fun loadVectors() {
        val text = javaClass.getResourceAsStream("/bridge_contract_vectors.json")!!
            .bufferedReader().readText()
        vectorsJson = JSONObject(text)
        bridgeVersion = vectorsJson.getString("bridge_protocol_version")
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private fun makeSession(
        bridgeProtocolVersion: String = bridgeVersion,
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

    private fun makeRequest(
        command: String = "app.info.get",
        capability: String = "app.info.get",
        version: String = bridgeVersion,
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

    private fun applySessionOverride(
        base: LiveViewSession,
        sessionOverride: Any?
    ): LiveViewSession {
        if (sessionOverride == null || sessionOverride == JSONObject.NULL) return base
        // empty array [] means no override
        if (sessionOverride is JSONArray) return base
        val overrideObj = sessionOverride as? JSONObject ?: return base

        var result = base

        if (overrideObj.has("capabilities")) {
            val capObj = overrideObj.optJSONObject("capabilities")
            if (capObj != null) {
                val caps = capObj.keys().asSequence()
                    .associateWith { capObj.getString(it) }
                result = result.copy(capabilities = caps)
            }
        }

        if (overrideObj.has("installed_packs")) {
            val installedPacksVal = overrideObj.get("installed_packs")
            when {
                installedPacksVal is JSONArray -> {
                    // empty array means no installed packs
                    result = result.copy(installedPacks = emptyMap())
                }
                installedPacksVal is JSONObject -> {
                    val packs = installedPacksVal.keys().asSequence()
                        .associateWith { installedPacksVal.getString(it) }
                    result = result.copy(installedPacks = packs)
                }
            }
        }

        if (overrideObj.has("route_required_packs")) {
            val packsArr = overrideObj.optJSONArray("route_required_packs")
            if (packsArr != null) {
                val packs = (0 until packsArr.length()).map { packsArr.getString(it) }
                result = result.copy(routeRequiredPacks = packs)
            }
        }

        // Floor conformance: allow session version axes to be overridden per-vector (COMPAT-01 / D-05)
        if (overrideObj.has("bridge_protocol_version")) {
            result = result.copy(bridgeProtocolVersion = overrideObj.getString("bridge_protocol_version"))
        }
        if (overrideObj.has("native_runtime_version")) {
            result = result.copy(nativeRuntimeVersion = overrideObj.getString("native_runtime_version"))
        }

        return result
    }

    private fun applyRequestOverride(
        base: BridgeRequestEnvelope,
        requestOverride: JSONObject
    ): BridgeRequestEnvelope {
        var result = base

        if (requestOverride.has("version")) result = result.copy(version = requestOverride.getString("version"))
        if (requestOverride.has("command")) result = result.copy(command = requestOverride.getString("command"))
        if (requestOverride.has("capability")) result = result.copy(capability = requestOverride.getString("capability"))
        if (requestOverride.has("route_id")) result = result.copy(routeId = requestOverride.getString("route_id"))
        if (requestOverride.has("active_route_id")) result = result.copy(activeRouteId = requestOverride.getString("active_route_id"))
        if (requestOverride.has("origin")) result = result.copy(origin = requestOverride.getString("origin"))
        // Floor conformance: allow request native_runtime_version to be overridden per-vector (COMPAT-01 / D-05)
        if (requestOverride.has("native_runtime_version")) {
            result = result.copy(nativeRuntimeVersion = requestOverride.getString("native_runtime_version"))
        }

        return result
    }

    // ── Data-driven vector test ───────────────────────────────────────────

    @Test
    fun `all bridge contract vectors pass status and denial-reason assertions`() {
        val vectors = vectorsJson.getJSONArray("vectors")

        for (i in 0 until vectors.length()) {
            val vector = vectors.getJSONObject(i)
            val id = vector.getString("id")
            val expectedOutcome = vector.getString("expected_outcome")
            val expectedReason: String? = if (vector.isNull("expected_denial_reason")) null
                                          else vector.optString("expected_denial_reason").takeIf { it.isNotBlank() }

            val requestOverride = vector.optJSONObject("request_override") ?: JSONObject()
            val sessionOverrideRaw = vector.opt("session_override")

            // Build permissive base session — everything passes unless override fires a specific check
            val baseSession = makeSession(
                bridgeProtocolVersion = bridgeVersion,
                nativeRuntimeVersion = "1.0.0",
                routeId = "dashboard",
                allowedOrigin = "https://app.example.com",
                capabilities = emptyMap(),
                installedPacks = emptyMap(),
                routeRequiredPacks = emptyList()
            )
            val session = applySessionOverride(baseSession, sessionOverrideRaw)

            // Build permissive base request — request capabilities are a fixed baseline
            // (session/request capabilities are decoupled: request uses "1.0.0" so
            // vec-007 session capability-version mismatch fires correctly when session has "2.0.0")
            val baseRequest = makeRequest(
                command = "app.info.get",
                capability = "app.info.get",
                version = bridgeVersion,
                nativeRuntimeVersion = "1.0.0",
                routeId = "dashboard",
                activeRouteId = "dashboard",
                origin = "https://app.example.com",
                capabilities = mapOf("app.info.get" to "1.0.0"),
                installedPacks = emptyMap()
            )
            val request = applyRequestOverride(baseRequest, requestOverride)

            // The ok-path config includes an appInfoDelegate so vec-003 canonical-version-ok succeeds
            // (without a delegate, app.info.get returns unavailable_capability even after all checks pass)
            val config = CrosswakeShellConfig(
                appInfoDelegate = object : AppInfoDelegate {
                    override fun getAppInfo() = mapOf("version" to "1.0.0", "build" to "test")
                }
            )

            val channel = BridgeChannel(session, transferCoordinator = null, config = config)
            val replyJson = JSONObject(channel.evaluateForTesting(request))

            assertEquals(
                "Vector $id: expected_outcome",
                expectedOutcome,
                replyJson.getString("status")
            )

            if (expectedReason != null) {
                val reason = replyJson
                    .getJSONObject("denial")
                    .getJSONObject("denial")
                    .getString("reason")
                assertEquals("Vector $id: expected_denial_reason", expectedReason, reason)
            }
        }
    }

    // ── Delegate escape-hatch: present → ok ──────────────────────────────

    @Test
    fun `bridge appInfoGet succeeds when appInfoDelegate is configured`() {
        val session = makeSession(
            capabilities = mapOf("app.info.get" to "1.0.0")
        )
        val config = CrosswakeShellConfig(
            appInfoDelegate = object : AppInfoDelegate {
                override fun getAppInfo() = mapOf("version" to "1.0.0")
            }
        )
        val request = makeRequest(
            command = "app.info.get",
            capability = "app.info.get",
            capabilities = mapOf("app.info.get" to "1.0.0")
        )

        val channel = BridgeChannel(session, transferCoordinator = null, config = config)
        val reply = JSONObject(channel.evaluateForTesting(request))

        assertEquals("Delegate present: status should be ok", "ok", reply.getString("status"))
    }

    // ── Delegate escape-hatch: absent → deny ─────────────────────────────

    @Test
    fun `bridge appInfoGet denies with unavailable_capability when appInfoDelegate is absent`() {
        val session = makeSession(
            capabilities = mapOf("app.info.get" to "1.0.0")
        )
        val config = CrosswakeShellConfig() // no appInfoDelegate
        val request = makeRequest(
            command = "app.info.get",
            capability = "app.info.get",
            capabilities = mapOf("app.info.get" to "1.0.0")
        )

        val channel = BridgeChannel(session, transferCoordinator = null, config = config)
        val reply = JSONObject(channel.evaluateForTesting(request))

        assertEquals("Delegate absent: status should be deny", "deny", reply.getString("status"))
        val reason = reply.getJSONObject("denial").getJSONObject("denial").getString("reason")
        assertEquals("Delegate absent: reason should be unavailable_capability", "unavailable_capability", reason)
    }
}
