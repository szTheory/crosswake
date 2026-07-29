package dev.crosswake.shell.core

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Android's half of the bridge reply leg.
 *
 * Android has been duplex since day one: `WebViewCompat.addWebMessageListener` hands the
 * page a `replyProxy` and the reply travels back as a JSON string. iOS had no return leg
 * at all until Phase 154 Plan 06, which is why the committed contract vectors gained a
 * `reply_leg_vectors` array.
 *
 * This suite consumes those same vectors to assert that Android's EXISTING behavior is
 * unchanged and needs no escaping fix: the adversarial reply content that iOS must escape
 * before it can be evaluated as JavaScript travels through Android's `postMessage` path
 * byte-intact, because it is never evaluated as source there.
 */
class BridgeReplyLegTest {

    private lateinit var vectorsJson: JSONObject
    private lateinit var bridgeVersion: String

    @Before
    fun loadVectors() {
        val text = javaClass.getResourceAsStream("/bridge_contract_vectors.json")!!
            .bufferedReader().readText()
        vectorsJson = JSONObject(text)
        bridgeVersion = vectorsJson.getString("bridge_protocol_version")
    }

    private fun replyLegVector(id: String): JSONObject {
        val vectors = vectorsJson.getJSONArray("reply_leg_vectors")
        for (index in 0 until vectors.length()) {
            val vector = vectors.getJSONObject(index)
            if (vector.getString("id") == id) return vector
        }
        throw AssertionError("missing committed reply-leg vector $id — regenerate with: mix crosswake.contract.gen")
    }

    private fun session(capabilities: Map<String, String>) = LiveViewSession(
        routeId = "saas-approval",
        url = "https://app.example.com/saas-approval",
        allowedOrigin = "https://app.example.com",
        bridgeProtocolVersion = bridgeVersion,
        nativeRuntimeVersion = "1.0.0",
        threadId = "test-thread-id",
        installedPacks = emptyMap(),
        routeRequiredPacks = emptyList(),
        capabilities = capabilities,
        declaredTransfers = emptyList()
    )

    private fun hapticsRequest(style: String, correlationId: String) = BridgeRequestEnvelope(
        protocol = "crosswake.bridge",
        version = bridgeVersion,
        command = "haptics.impact",
        capability = "haptics.impact",
        routeId = "saas-approval",
        activeRouteId = "saas-approval",
        origin = "https://app.example.com",
        nativeRuntimeVersion = "1.0.0",
        correlationId = correlationId,
        capabilities = mapOf("haptics.impact" to "1.0.0"),
        installedPacks = emptyMap(),
        payload = mapOf("style" to style)
    )

    private fun channel(): BridgeChannel {
        val config = CrosswakeShellConfig(hapticsDelegate = object : HapticsDelegate {
            override fun impact(style: String) = Unit
        })
        return BridgeChannel(
            session = session(mapOf("haptics.impact" to "1.0.0")),
            transferCoordinator = null,
            config = config
        )
    }

    @Test
    fun `the committed reply-leg vectors are present and name the shipped landing pad`() {
        val ok = replyLegVector("vec-reply-001-ok-landing-pad")
        val adversarial = replyLegVector("vec-reply-002-adversarial-denial-message")

        // The landing pad is an iOS-side concern (Android replies through the
        // replyProxy, never through evaluated JavaScript), but it is the same shipped
        // contract value in the same shared vector file — asserting it here keeps the
        // two native suites reading one source of truth.
        assertEquals("window.crosswakeBridge.__reply", ok.getString("landing_pad"))
        assertEquals("window.crosswakeBridge.__reply", adversarial.getString("landing_pad"))
        assertTrue(adversarial.getBoolean("adversarial"))
    }

    @Test
    fun `the ok reply-leg vector matches the shape Android's duplex path emits`() {
        val vector = replyLegVector("vec-reply-001-ok-landing-pad")
        val expected = vector.getJSONObject("reply")

        val reply = JSONObject(
            channel().evaluateForTesting(
                hapticsRequest(
                    style = expected.getJSONObject("payload").getString("style"),
                    correlationId = expected.getString("correlation_id")
                )
            )
        )

        assertEquals(expected.getString("protocol"), reply.getString("protocol"))
        assertEquals(expected.getString("version"), reply.getString("version"))
        assertEquals(expected.getString("command"), reply.getString("command"))
        assertEquals(expected.getString("route_id"), reply.getString("route_id"))
        assertEquals(expected.getString("correlation_id"), reply.getString("correlation_id"))
        assertEquals(expected.getString("status"), reply.getString("status"))
        assertEquals(
            expected.getJSONObject("payload").getString("style"),
            reply.getJSONObject("payload").getString("style")
        )
    }

    @Test
    fun `adversarial reply content survives Android's duplex path byte-intact`() {
        val vector = replyLegVector("vec-reply-002-adversarial-denial-message")
        val adversarial = vector
            .getJSONObject("reply")
            .getJSONObject("denial")
            .getJSONObject("denial")
            .getString("message")

        assertTrue("fixture must carry a quote", adversarial.contains("\""))
        assertTrue("fixture must carry a backslash", adversarial.contains("\\"))
        assertTrue("fixture must carry a newline", adversarial.contains("\n"))
        assertTrue("fixture must carry U+2028", adversarial.contains("\u2028"))
        assertTrue("fixture must carry U+2029", adversarial.contains("\u2029"))

        // Android never evaluates the reply as source — it posts a JSON string through
        // the replyProxy — so the same content that iOS must escape simply round-trips.
        val serialized = channel().evaluateForTesting(
            hapticsRequest(style = adversarial, correlationId = "cwbridge-e1-reply-vector-deny")
        )
        val reply = JSONObject(serialized)

        assertNotNull(serialized)
        assertEquals(adversarial, reply.getJSONObject("payload").getString("style"))
        assertEquals("cwbridge-e1-reply-vector-deny", reply.getString("correlation_id"))
    }
}
