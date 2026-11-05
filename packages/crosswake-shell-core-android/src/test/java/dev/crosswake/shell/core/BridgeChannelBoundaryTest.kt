package dev.crosswake.shell.core

import org.json.JSONException
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/**
 * JVM boundary tests for the bridge request envelope. JVM evidence only: these run against
 * the AOSP-derived org.json test artifact, not on a device.
 */
class BridgeChannelBoundaryTest {

    @Test
    fun `envelope accepts a well formed request`() {
        val json = BridgeFixtures.validEnvelopeJson()
        val envelope = BridgeRequestEnvelope(json)

        assertEquals("crosswake.bridge", envelope.protocol)
        assertEquals(BridgeFixtures.bridgeVersion(), envelope.version)
        assertEquals("app.info.get", envelope.command)
        assertEquals("app.info.get", envelope.capability)
        assertEquals("dashboard", envelope.routeId)
        assertEquals("dashboard", envelope.activeRouteId)
        assertEquals("https://app.example.com", envelope.origin)
        assertEquals("1.0.0", envelope.nativeRuntimeVersion)
        assertEquals("test-correlation-id", envelope.correlationId)
        assertEquals(emptyMap<String, String>(), envelope.capabilities)
    }

    @Test
    fun `envelope rejects non string required fields on the JVM`() {
        var ran = 0
        for (field in BridgeFixtures.REQUIRED_STRING_FIELDS) {
            for (bad in listOf<Any>(JSONObject.NULL, 42)) {
                val json = JSONObject(BridgeFixtures.validEnvelopeJson().toString()).put(field, bad)
                try {
                    BridgeRequestEnvelope(json)
                    fail("CW-ENVELOPE-ACCEPTED $field=$bad should have been rejected")
                } catch (_: JSONException) {
                    // expected: fail closed
                }
                ran++
            }
        }
        assertEquals("CW-ENVELOPE-CASES expected 18", 18, ran)
    }

    private fun channel() = BridgeChannel(
        BridgeFixtures.makeSession(),
        transferCoordinator = null,
        config = CrosswakeShellConfig()
    )

    @Test
    fun `parse body returns null for missing garbage and non string bodies on the JVM`() {
        val channel = channel()
        assertNull(channel.parseBody(null))
        assertNull(channel.parseBody(""))
        assertNull(channel.parseBody("[]"))
        assertNotNull(channel.parseBody(BridgeFixtures.validEnvelopeJson().toString()))
        val nullRoute = BridgeFixtures.validEnvelopeJson().put("route_id", JSONObject.NULL)
        assertNull(channel.parseBody(nullRoute.toString()))
    }

    @Test
    fun `listener gate allows only the main frame from the exact allowed origin`() {
        val channel = channel()
        val origin = "https://app.example.com"
        assertTrue(channel.listenerAllows(true, origin))
        assertFalse(channel.listenerAllows(false, origin))
        assertFalse(channel.listenerAllows(true, "$origin/"))
    }

    // --- D-12 evaluate boundaries -------------------------------------------------------

    private val appInfoDelegate = object : AppInfoDelegate {
        override fun getAppInfo(): Map<String, String> = mapOf("platform" to "android")
    }

    /** A channel whose baseline request (BridgeFixtures.makeRequest defaults) returns ok. */
    private fun baselineChannel(
        session: LiveViewSession = BridgeFixtures.makeSession(
            capabilities = mapOf("app.info.get" to "1.0.0")
        ),
        config: CrosswakeShellConfig = CrosswakeShellConfig(appInfoDelegate = appInfoDelegate),
        transferCoordinator: dev.crosswake.shell.core.transfer.TransferCoordinator? = null
    ) = BridgeChannel(session, transferCoordinator, config)

    private fun assertBaselineOk(channel: BridgeChannel) {
        val reply = channel.evaluateForTesting(BridgeFixtures.makeRequest())
        assertEquals("CW-BASELINE-NOT-OK $reply", "ok", BridgeFixtures.status(reply))
    }

    private fun assertDenied(reason: String, label: String, reply: String) {
        assertEquals("CW-NOT-DENIED $label $reply", "deny", BridgeFixtures.status(reply))
        assertEquals("CW-REASON $label", reason, BridgeFixtures.denialReason(reply))
    }

    @Test
    fun `wrong protocol is denied with compatibility_mismatch`() {
        val channel = baselineChannel()
        assertBaselineOk(channel)
        val base = BridgeFixtures.makeRequest()
        var ran = 0
        for (protocol in listOf("crosswake.bridge2", "", "Crosswake.Bridge")) {
            val reply = channel.evaluateForTesting(base.copy(protocol = protocol))
            assertDenied("compatibility_mismatch", "protocol=[$protocol]", reply)
            ran++
        }
        assertEquals("CW-PROTOCOL-CASES expected 3", 3, ran)
    }

    @Test
    fun `malformed request version is denied and short forms are accepted`() {
        val channel = baselineChannel()
        assertBaselineOk(channel)
        val base = BridgeFixtures.makeRequest()
        var denied = 0
        for (version in listOf("", "abc", "1.0.0-beta", "1.0.0.0", "99999999999.0.0")) {
            val reply = channel.evaluateForTesting(base.copy(version = version))
            assertDenied("compatibility_mismatch", "version=[$version]", reply)
            denied++
        }
        var accepted = 0
        for (version in listOf("1", "1.0")) {
            val reply = channel.evaluateForTesting(base.copy(version = version))
            assertEquals("CW-SHORT-VERSION-DENIED version=[$version] $reply", "ok", BridgeFixtures.status(reply))
            accepted++
        }
        assertEquals("CW-VERSION-DENIALS expected 5", 5, denied)
        assertEquals("CW-VERSION-ACCEPTS expected 2", 2, accepted)
    }

    @Test
    fun `route id mismatch is denied in each direction with inactive_route`() {
        val channel = baselineChannel()
        assertBaselineOk(channel)
        val base = BridgeFixtures.makeRequest()
        var ran = 0
        val cases = listOf(
            "route_id differs" to base.copy(routeId = "settings"),
            "active_route_id differs" to base.copy(activeRouteId = "settings")
        )
        for ((label, request) in cases) {
            assertDenied("inactive_route", label, channel.evaluateForTesting(request))
            ran++
        }
        assertEquals("CW-ROUTE-CASES expected 2", 2, ran)
    }

    @Test
    fun `origin near misses are denied with origin_denied`() {
        val channel = baselineChannel()
        assertBaselineOk(channel)
        val base = BridgeFixtures.makeRequest()
        var ran = 0
        val origins = listOf(
            "https://app.example.com/",
            "http://app.example.com",
            "https://app.example.com:8443",
            "https://APP.example.com",
            "https://app.example.com@evil.test",
            "null",
            ""
        )
        for (origin in origins) {
            assertDenied("origin_denied", "origin=[$origin]", channel.evaluateForTesting(base.copy(origin = origin)))
            ran++
        }
        assertEquals("CW-ORIGIN-CASES expected 7", 7, ran)
    }

    @Test
    fun `deny reply has an empty payload and never echoes a request secret`() {
        val sentinel = "CW-SENTINEL-SECRET-198"
        val channel = baselineChannel()
        assertBaselineOk(channel)
        val base = BridgeFixtures.makeRequest()

        val denied = channel.evaluateForTesting(
            base.copy(
                origin = "https://evil.test",
                payload = mapOf("answer" to sentinel),
                capabilities = mapOf("app.info.get" to "1.0.0", "secret_capability" to sentinel)
            )
        )
        assertDenied("origin_denied", "sentinel in payload and capabilities", denied)

        val json = JSONObject(denied)
        assertEquals("CW-PAYLOAD-NOT-EMPTY $denied", 0, json.getJSONObject("payload").length())
        val inner = json.getJSONObject("denial").getJSONObject("denial")
        for (key in listOf("reason", "code", "message", "route_id", "hint")) {
            assertTrue("CW-DENIAL-KEY-MISSING $key", inner.has(key))
        }
        assertFalse("CW-SECRET-ECHOED $denied", denied.contains(sentinel))

        // Positive control: correlation_id is echoed by design, so the search can find an echo.
        val echoed = channel.evaluateForTesting(
            base.copy(origin = "https://evil.test", correlationId = sentinel)
        )
        assertTrue("CW-CONTROL-NOT-FOUND the echo search cannot see a known echo", echoed.contains(sentinel))
    }
}
