package dev.crosswake.shell

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowActivityManager
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLConnection
import java.net.URLStreamHandler
import java.net.URLStreamHandlerFactory

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.R], shadows = [ShadowActivityManager::class])
class DiagnosticExportTest {

    private lateinit var context: Context
    private lateinit var shadowActivityManager: ShadowActivityManager
    private val capturedPayloads = mutableListOf<String>()

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        shadowActivityManager = Shadows.shadowOf(activityManager)
        
        try {
            URL.setURLStreamHandlerFactory(object : URLStreamHandlerFactory {
                override fun createURLStreamHandler(protocol: String): URLStreamHandler? {
                    if (protocol == "https" || protocol == "http") {
                        return object : URLStreamHandler() {
                            override fun openConnection(url: URL): URLConnection {
                                return MockHttpURLConnection(url) { payload ->
                                    capturedPayloads.add(payload)
                                }
                            }
                        }
                    }
                    return null
                }
            })
        } catch (e: Error) {
            // Factory can only be set once per JVM. Ignore if already set.
        }
    }

    @Test
    fun testDiagnosticExportFiresPostWithCorrectEnvelope() {
        // Seed the shadow ActivityManager with a mock crash exit reason
        shadowActivityManager.addApplicationExitInfo(context.packageName, 1234, ApplicationExitInfo.REASON_CRASH, 1)

        // Trigger the export
        DiagnosticExportManager.start(context, "https://api.example.com/export", "1.2.3")

        // Wait a bit for the executor to finish since it's on a background thread
        Thread.sleep(200)

        // Assert the payload
        assertEquals("Should capture 1 payload", 1, capturedPayloads.size)
        
        val envelope = JSONObject(capturedPayloads[0])
        assertEquals("1.0", envelope.getString("schema_version"))
        assertEquals("native", envelope.getString("layer"))
        assertEquals("android", envelope.getString("platform"))
        assertEquals("1.2.3", envelope.getString("native_runtime_version"))
        assertEquals("crash", envelope.getString("kind"))
        assertNotNull(envelope.getString("correlation_id"))
        assertNotNull(envelope.getString("observed_at"))
        
        val nativeDiagnostic = envelope.getJSONObject("native_diagnostic")
        assertEquals("app_exit_info", nativeDiagnostic.getString("source"))
        assertEquals("crash", nativeDiagnostic.getString("exit_reason"))
    }

    class MockHttpURLConnection(url: URL, private val onPayloadCaptured: (String) -> Unit) : HttpURLConnection(url) {
        private val outputStreamMock = java.io.ByteArrayOutputStream()
        
        override fun connect() {}
        override fun disconnect() {}
        override fun usingProxy(): Boolean = false
        
        override fun getOutputStream(): java.io.OutputStream {
            return outputStreamMock
        }
        
        override fun getResponseCode(): Int {
            onPayloadCaptured(outputStreamMock.toString("UTF-8"))
            return 200
        }
    }
}
