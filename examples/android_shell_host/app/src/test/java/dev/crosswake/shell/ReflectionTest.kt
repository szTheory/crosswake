package dev.crosswake.shell

import android.app.ApplicationExitInfo
import org.junit.Test

class ReflectionTest {
    @Test
    fun testExitInfo() {
        val info = ApplicationExitInfo::class.java.getDeclaredConstructor().apply { isAccessible = true }.newInstance()
        val reasonField = ApplicationExitInfo::class.java.getDeclaredField("mReason").apply { isAccessible = true }
        reasonField.set(info, ApplicationExitInfo.REASON_CRASH)
        
        val timestampField = ApplicationExitInfo::class.java.getDeclaredField("mTimestamp").apply { isAccessible = true }
        timestampField.set(info, 1234567890000L)
        
        println("Reason: \${info.reason}")
    }
}
