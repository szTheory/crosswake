package dev.crosswake.shell

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import dev.crosswake.shell.transfer.TransferCoordinator

class NativeCaptureActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val routeId = intent.getStringExtra(EXTRA_ROUTE_ID).orEmpty()
        val routeTitle = intent.getStringExtra(EXTRA_ROUTE_TITLE).orEmpty()
        val runtimeLabel = intent.getStringExtra(EXTRA_RUNTIME_LABEL) ?: DEFAULT_RUNTIME_LABEL
        val transferId = intent.getStringExtra(EXTRA_TRANSFER_ID).orEmpty()

        val transferCoordinator = TransferCoordinator(
            routeId = routeId,
            declaredTransfers = listOf(
                ShellManifest.TransferSeam(
                    id = transferId,
                    intent = "upload",
                    direction = "inbound",
                    source = "native_capture",
                    destination = null,
                    verification = "required",
                    mediaTypes = listOf("image/*"),
                    states = listOf("queued", "preparing", "transferring", "awaiting_network", "verifying", "complete", "failed", "canceled")
                )
            )
        )

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val inset = (24 * resources.displayMetrics.density).toInt()
            setPadding(inset, inset, inset, inset)
        }

        ViewCompat.setOnApplyWindowInsetsListener(root) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPadding(
                view.paddingLeft,
                view.paddingTop + bars.top,
                view.paddingRight,
                view.paddingBottom + bars.bottom
            )
            insets
        }

        root.addView(TextView(this).apply {
            text = routeTitle
            textSize = 28f
        })

        root.addView(TextView(this).apply {
            text = runtimeLabel
            textSize = 14f
        })

        val stagedStatus = TextView(this).apply {
            text = "Capture media locally, stage it inside the shell, then hand it off through the declared transfer seam."
            textSize = 16f
        }

        root.addView(stagedStatus)

        root.addView(Button(this).apply {
            text = "Stage For Transfer"
            setOnClickListener {
                val staged = transferCoordinator.stageCapturedMedia(
                    transferId = transferId,
                    localPath = "/tmp/$transferId-captured.jpg",
                    mediaType = "image/jpeg",
                    bytes = 524_288
                )

                stagedStatus.text =
                    if (staged == null) {
                        "Transfer seam unavailable. Captured media stays local until the declared handoff exists."
                    } else {
                        "Captured locally. Transfer handoff stays explicit until `$transferId` starts."
                    }
            }
        })

        root.addView(Button(this).apply {
            text = "Cancel Capture"
            setOnClickListener { finish() }
        })

        root.addView(TextView(this).apply {
            text = "Route: $routeId"
            textSize = 14f
        })

        setContentView(root)
    }

    companion object {
        private const val EXTRA_ROUTE_ID = "route_id"
        private const val EXTRA_ROUTE_TITLE = "route_title"
        private const val EXTRA_RUNTIME_LABEL = "runtime_label"
        private const val EXTRA_TRANSFER_ID = "transfer_id"
        private const val DEFAULT_RUNTIME_LABEL = "Native capture"

        fun intent(
            context: Context,
            routeId: String,
            routeTitle: String,
            runtimeLabel: String,
            transferId: String
        ): Intent {
            return Intent(context, NativeCaptureActivity::class.java)
                .putExtra(EXTRA_ROUTE_ID, routeId)
                .putExtra(EXTRA_ROUTE_TITLE, routeTitle)
                .putExtra(EXTRA_RUNTIME_LABEL, runtimeLabel)
                .putExtra(EXTRA_TRANSFER_ID, transferId)
        }
    }
}
