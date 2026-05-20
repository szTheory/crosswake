package dev.crosswake.shell.packs

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import dev.crosswake.shell.R
import kotlinx.coroutines.launch

class RequiredPackActivity : AppCompatActivity() {
    // This screen stays bound to PackStore-owned lifecycle truth.
    private lateinit var packStore: PackStore
    private lateinit var routeId: String
    private lateinit var runtimeLabel: String
    private lateinit var packId: String
    private lateinit var requiredVersion: String
    private lateinit var currentStatus: RequiredPackStatus

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_required_pack)

        packStore = PackStore.bundled(this)
        routeId = intent.getStringExtra(EXTRA_ROUTE_ID).orEmpty()
        runtimeLabel = intent.getStringExtra(EXTRA_RUNTIME_LABEL).orEmpty()
        packId = intent.getStringExtra(EXTRA_PACK_ID).orEmpty()
        requiredVersion = intent.getStringExtra(EXTRA_REQUIRED_VERSION).orEmpty()

        currentStatus = packStore.blockingStatus(listOf("$packId@$requiredVersion"))
            ?: RequiredPackStatus(
                packId = packId,
                requiredVersion = requiredVersion,
                state = PackState.NOT_INSTALLED,
                installedVersion = null,
                bytes = null,
                verifiedAt = null,
                integrityStatus = null
            )

        bind(currentStatus)
    }

    private fun bind(status: RequiredPackStatus) {
        currentStatus = status

        findViewById<TextView>(R.id.required_pack_title).text = "Required pack"
        findViewById<TextView>(R.id.required_pack_runtime).text = runtimeLabel
        findViewById<TextView>(R.id.required_pack_state).text = status.state.wireValue
        findViewById<TextView>(R.id.required_pack_message).text =
            "Crosswake blocked route activation until this declared pack verifies as available."
        findViewById<TextView>(R.id.required_pack_name).text = status.packId
        findViewById<TextView>(R.id.required_pack_required_version).text = status.requiredVersion
        findViewById<TextView>(R.id.required_pack_installed_version).text = status.installedVersion ?: "none"
        findViewById<TextView>(R.id.required_pack_size).text = status.bytes?.let { "$it bytes" } ?: "unknown"
        findViewById<TextView>(R.id.required_pack_verified_at).text = status.verifiedAt ?: "none"
        findViewById<TextView>(R.id.required_pack_route).text = "Route: $routeId"

        val stage = findViewById<TextView>(R.id.required_pack_stage)
        stage.text = status.installStage?.label ?: status.failureReason ?: ""
        stage.visibility = if (stage.text.isNullOrBlank()) View.GONE else View.VISIBLE

        val primary = findViewById<Button>(R.id.required_pack_primary)
        primary.text = when (status.state) {
            PackState.NOT_INSTALLED -> "Install Required Pack"
            PackState.STALE -> "Update Pack"
            PackState.FAILED -> "Retry Install"
            PackState.AVAILABLE -> "Reverify Pack"
            PackState.INSTALLING -> "Installing"
            PackState.INVALIDATING -> "Invalidating"
            PackState.CHECKING -> "Checking"
        }
        primary.isEnabled = status.state !in listOf(PackState.CHECKING, PackState.INSTALLING, PackState.INVALIDATING)
        primary.setOnClickListener {
            lifecycleScope.launch {
                val updated = packStore.installRequiredPack(currentStatus)
                bind(updated)
                if (updated.state == PackState.AVAILABLE) {
                    setResult(Activity.RESULT_OK)
                    finish()
                }
            }
        }

        val invalidate = findViewById<Button>(R.id.required_pack_invalidate)
        invalidate.visibility = if (status.installedVersion != null || status.lastKnownVersion != null) View.VISIBLE else View.GONE
        invalidate.setOnClickListener {
            lifecycleScope.launch {
                bind(packStore.invalidatePack(currentStatus))
            }
        }
    }

    companion object {
        private const val EXTRA_ROUTE_ID = "route_id"
        private const val EXTRA_RUNTIME_LABEL = "runtime_label"
        private const val EXTRA_PACK_ID = "pack_id"
        private const val EXTRA_REQUIRED_VERSION = "required_version"

        fun intent(
            context: Context,
            routeId: String,
            runtimeLabel: String,
            status: RequiredPackStatus
        ): Intent {
            return Intent(context, RequiredPackActivity::class.java).apply {
                putExtra(EXTRA_ROUTE_ID, routeId)
                putExtra(EXTRA_RUNTIME_LABEL, runtimeLabel)
                putExtra(EXTRA_PACK_ID, status.packId)
                putExtra(EXTRA_REQUIRED_VERSION, status.requiredVersion)
            }
        }
    }
}
