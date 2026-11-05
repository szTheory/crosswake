package dev.crosswake.shell.core

import org.json.JSONException
import org.json.JSONObject
import org.junit.Assert.assertEquals
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
}
