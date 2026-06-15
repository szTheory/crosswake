package dev.crosswake.shell.core

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.os.Build
import android.util.Log
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.Executors

object DiagnosticExportManager {
    private const val TAG = "DiagnosticExport"
    private const val SCHEMA_VERSION = "1.0"
    private val executor = Executors.newSingleThreadExecutor()

    fun start(context: Context, endpointUrl: String, runtimeVersion: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return // getHistoricalProcessExitReasons requires API 30+
        }

        executor.execute {
            try {
                val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val exitReasons = activityManager.getHistoricalProcessExitReasons(context.packageName, 0, 10)

                for (info in exitReasons) {
                    // Only process recent or specific reasons if needed. We'll just export them all for this proof.
                    // In a real app, we would track which ones were already sent.
                    exportExitInfo(info, endpointUrl, runtimeVersion)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to capture diagnostics", e)
            }
        }
    }

    private fun exportExitInfo(info: ApplicationExitInfo, endpointUrl: String, runtimeVersion: String) {
        val (kind, exitReason) = mapExitReason(info.reason)
        
        val nativeDiagnostic = JSONObject().apply {
            put("source", "app_exit_info")
            put("exit_reason", exitReason)
        }

        val observedAt = formatIso8601(info.timestamp)
        val correlationId = UUID.randomUUID().toString()

        val envelope = JSONObject().apply {
            put("schema_version", SCHEMA_VERSION)
            put("layer", "native")
            put("platform", "android")
            put("native_runtime_version", runtimeVersion)
            put("kind", kind)
            put("correlation_id", correlationId)
            put("observed_at", observedAt)
            put("native_diagnostic", nativeDiagnostic)
        }

        fireAndForgetPost(endpointUrl, envelope)
    }

    private fun fireAndForgetPost(endpointUrl: String, payload: JSONObject) {
        var connection: HttpURLConnection? = null
        try {
            val url = URL(endpointUrl)
            connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            connection.setRequestProperty("Accept", "application/json")
            connection.doOutput = true
            connection.connectTimeout = 10000
            connection.readTimeout = 10000

            OutputStreamWriter(connection.outputStream, "UTF-8").use { writer ->
                writer.write(payload.toString())
                writer.flush()
            }

            val responseCode = connection.responseCode
            Log.d(TAG, "Diagnostic export response: $responseCode")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to export diagnostic payload", e)
        } finally {
            connection?.disconnect()
        }
    }

    private fun mapExitReason(reason: Int): Pair<String, String> {
        return when (reason) {
            ApplicationExitInfo.REASON_ANR -> "hang" to "anr"
            ApplicationExitInfo.REASON_CRASH, ApplicationExitInfo.REASON_CRASH_NATIVE, ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> "crash" to "crash"
            ApplicationExitInfo.REASON_LOW_MEMORY,
            ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE -> "termination" to "low_memory"
            ApplicationExitInfo.REASON_USER_REQUESTED, ApplicationExitInfo.REASON_EXIT_SELF, ApplicationExitInfo.REASON_PERMISSION_CHANGE, ApplicationExitInfo.REASON_USER_STOPPED -> "termination" to "user_requested"
            ApplicationExitInfo.REASON_DEPENDENCY_DIED, ApplicationExitInfo.REASON_SIGNALED -> "termination" to "abnormal_exit"
            else -> "termination" to "other"
        }
    }

    private fun formatIso8601(timestamp: Long): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.format(Date(timestamp))
    }
}
