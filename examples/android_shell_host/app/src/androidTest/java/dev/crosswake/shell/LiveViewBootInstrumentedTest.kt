package dev.crosswake.shell

import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class LiveViewBootInstrumentedTest {
    @Test
    fun appLinkLaunchMountsBoundedWebView() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("https://example.crosswake.invalid/native/claims/claim-1/capture")
        }

        ActivityScenario.launch<MainActivity>(intent).use { scenario ->
            val webViewMounted = waitForUiCondition {
                var mounted = false

                scenario.onActivity { activity ->
                    assertNotNull(activity.findViewById(android.R.id.content))

                    mounted =
                        activity.findViewById<android.view.View>(LiveViewFragment.WEB_VIEW_ID) != null ||
                            activity.supportFragmentManager.findFragmentByTag(LiveViewFragment.TAG) != null
                }

                mounted
            }

            assertTrue("expected LiveView surface to mount for the SaaS approval route", webViewMounted)
        }
    }

    private fun waitForUiCondition(timeoutMs: Long = 2_000, condition: () -> Boolean): Boolean {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val deadline = SystemClock.elapsedRealtime() + timeoutMs

        while (SystemClock.elapsedRealtime() < deadline) {
            instrumentation.waitForIdleSync()

            if (condition()) {
                return true
            }

            SystemClock.sleep(50)
        }

        instrumentation.waitForIdleSync()
        return condition()
    }
}
