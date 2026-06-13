package dev.crosswake.shell.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CrosswakeShellConfigTest {

    @Test
    fun `test config without delegates has no registered capabilities`() {
        val config = CrosswakeShellConfig()
        assertTrue(config.registeredCapabilities.isEmpty())
    }

    @Test
    fun `test config with route delegate exposes route capabilities`() {
        val mockRouteDelegate = object : RouteDelegate {
            override val registeredRoutes: List<String> = listOf("user_profile", "settings")
            
            override fun isRouteRegistered(routeId: String): Boolean {
                return registeredRoutes.contains(routeId)
            }
        }

        val config = CrosswakeShellConfig(routeDelegate = mockRouteDelegate)
        
        val caps = config.registeredCapabilities
        assertEquals(2, caps.size)
        assertTrue(caps.contains("route.user_profile"))
        assertTrue(caps.contains("route.settings"))
    }

    @Test
    fun `test config with all delegates exposes all capabilities`() {
        val mockRouteDelegate = object : RouteDelegate {
            override val registeredRoutes: List<String> = listOf("camera")
            override fun isRouteRegistered(routeId: String) = registeredRoutes.contains(routeId)
        }

        val config = CrosswakeShellConfig(
            appInfoDelegate = object : AppInfoDelegate { override fun getAppInfo() = emptyMap<String, String>() },
            hapticsDelegate = object : HapticsDelegate { override fun impact(style: String) {} },
            permissionStatusDelegate = object : PermissionStatusDelegate { override fun getStatus(alias: String) = null },
            notificationTokenDelegate = object : NotificationTokenDelegate { 
                override fun fetch(): NotificationTokenDelegate.Result = NotificationTokenDelegate.Result.Denied("reason", "message", "hint") 
            },
            shareDelegate = object : ShareDelegate { override fun invoke(payload: Map<String, String>) {} },
            filesPickDelegate = object : FilesPickDelegate { 
                override fun pick(payload: Map<String, String>, correlationId: String) = FilesPickResult.Failure("error", "message") 
            },
            routeDelegate = mockRouteDelegate
        )

        val caps = config.registeredCapabilities
        assertEquals(7, caps.size)
        assertTrue(caps.contains("app.info.get"))
        assertTrue(caps.contains("haptics.impact"))
        assertTrue(caps.contains("permissions.status"))
        assertTrue(caps.contains("notification_token"))
        assertTrue(caps.contains("share.invoke"))
        assertTrue(caps.contains("file_picker"))
        assertTrue(caps.contains("route.camera"))
    }
}
