package dev.crosswake.shell

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.FrameLayout
import android.widget.TextView
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import dev.crosswake.shell.NativeCaptureActivity
import dev.crosswake.shell.packs.RequiredPackActivity

class MainActivity : AppCompatActivity(), LiveViewFragment.Host {
    private lateinit var activationCoordinator: ActivationCoordinator
    private var filePickerCoordinator: FilePickerCoordinator? = null
    private var unavailableDialog: AlertDialog? = null
    private val requiredPackLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        activationCoordinator = ActivationCoordinator.bundled(this)
        render(
            activationCoordinator.handleIntent(intent, fallbackSource = ActivationSource.COLD_START),
            preserveCurrentRoute = false
        )
    }
    private val nativeCaptureLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        activationCoordinator = ActivationCoordinator.bundled(this)
        render(
            activationCoordinator.handleIntent(intent, fallbackSource = ActivationSource.COLD_START),
            preserveCurrentRoute = false
        )
    }
    private val filePickerLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        filePickerCoordinator?.consumeResult(result.resultCode, result.data)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        activationCoordinator = ActivationCoordinator.bundled(this)

        if (savedInstanceState == null) {
            render(activationCoordinator.bootstrapIfNeeded(intent), preserveCurrentRoute = false)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        render(activationCoordinator.handleIntent(intent), preserveCurrentRoute = false)
    }

    override fun allowNavigation(url: String): Boolean {
        return when (val decision = activationCoordinator.resolveNavigation(url)) {
            NavigationDecision.Allow -> true
            is NavigationDecision.Deny -> {
                render(ShellPresentation.Denied(decision.denial), preserveCurrentRoute = true)
                false
            }
        }
    }

    override fun filesPick(payload: Map<String, String>, correlationId: String): FilesPickResult {
        val coordinator = filePickerCoordinator
            ?: return FilesPickResult.Denied(
                reason = "undeclared_capability",
                message = "This route does not declare the requested transfer seam.",
                hint = "Retry only after mounting a LiveView session with a manifest-declared native_picker transfer."
            )

        return coordinator.pick(payload, correlationId)
    }

    private fun render(presentation: ShellPresentation, preserveCurrentRoute: Boolean) {
        when (presentation) {
            ShellPresentation.Booting -> showUnavailableSurface(
                RouteDenialPresentation(
                    reason = RouteDenialReason.COMPATIBILITY_MISMATCH,
                    title = "Shell boot blocked",
                    message = "Crosswake could not resolve a manifest-first activation request.",
                    hint = "Retry after confirming bundled fixtures are present.",
                    routeId = null,
                    actions = listOf(RouteUnavailableAction.RETRY),
                    safeFallbackUrl = null
                ),
                preserveCurrentRoute = false
            )

            is ShellPresentation.RequiredPack -> showRequiredPack(presentation.requiredPack)
            is ShellPresentation.NativeCapture -> showNativeCapture(presentation.nativeCapture)
            is ShellPresentation.Denied -> showUnavailableSurface(presentation.denial, preserveCurrentRoute)
            is ShellPresentation.LiveView -> showLiveView(presentation.session)
        }
    }

    private fun showRequiredPack(requiredPack: RequiredPackPresentation) {
        filePickerCoordinator = null
        unavailableDialog?.dismiss()
        unavailableDialog = null
        requiredPackLauncher.launch(
            RequiredPackActivity.intent(
                context = this,
                routeId = requiredPack.routeId,
                runtimeLabel = requiredPack.runtimeLabel,
                status = requiredPack.status
            )
        )
    }

    private fun showNativeCapture(nativeCapture: NativeCapturePresentation) {
        filePickerCoordinator = null
        unavailableDialog?.dismiss()
        unavailableDialog = null
        nativeCaptureLauncher.launch(
            NativeCaptureActivity.intent(
                context = this,
                routeId = nativeCapture.routeId,
                routeTitle = nativeCapture.routeTitle,
                runtimeLabel = nativeCapture.runtimeLabel,
                transferId = nativeCapture.transferId
            )
        )
    }

    private fun showLiveView(session: LiveViewSession) {
        unavailableDialog?.dismiss()
        unavailableDialog = null
        filePickerCoordinator =
            activationCoordinator.currentTransferCoordinator?.let { transferCoordinator ->
                FilePickerCoordinator(
                    context = this,
                    transferCoordinator = transferCoordinator,
                    launchPicker = filePickerLauncher::launch
                )
            }

        val container = FrameLayout(this).apply {
            id = CONTAINER_ID
        }

        ViewCompat.setOnApplyWindowInsetsListener(container) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }

        setContentView(container)

        val existing = supportFragmentManager.findFragmentByTag(LiveViewFragment.TAG) as? LiveViewFragment
        if (existing?.represents(session) == true) {
            return
        }

        supportFragmentManager
            .beginTransaction()
            .replace(CONTAINER_ID, LiveViewFragment.newInstance(session), LiveViewFragment.TAG)
            .commitNowAllowingStateLoss()
    }

    private fun showUnavailableSurface(denial: RouteDenialPresentation, preserveCurrentRoute: Boolean) {
        filePickerCoordinator = null
        if (preserveCurrentRoute && supportFragmentManager.findFragmentByTag(LiveViewFragment.TAG) != null) {
            showUnavailableDialog(denial)
            return
        }

        unavailableDialog?.dismiss()
        unavailableDialog = null

        val root = layoutInflater.inflate(R.layout.activity_route_unavailable, null)
        bindUnavailableView(root, denial)
        setContentView(root)
    }

    private fun showUnavailableDialog(denial: RouteDenialPresentation) {
        unavailableDialog?.dismiss()

        val dialogView = LayoutInflater.from(this).inflate(R.layout.activity_route_unavailable, null)
        bindUnavailableView(dialogView, denial)

        unavailableDialog = AlertDialog.Builder(this)
            .setView(dialogView)
            .setCancelable(true)
            .create()
            .also { it.show() }
    }

    private fun bindUnavailableView(root: View, denial: RouteDenialPresentation) {
        root.findViewById<TextView>(R.id.route_unavailable_title).text = denial.title
        root.findViewById<TextView>(R.id.route_unavailable_message).text = denial.message
        root.findViewById<TextView>(R.id.route_unavailable_reason).text = denial.reason.wireValue

        val hint = root.findViewById<TextView>(R.id.route_unavailable_hint)
        hint.text = denial.hint
        hint.visibility = if (denial.hint.isNullOrBlank()) View.GONE else View.VISIBLE

        val routeId = root.findViewById<TextView>(R.id.route_unavailable_route_id)
        routeId.text = denial.routeId?.let { "Route: $it" }
        routeId.visibility = if (denial.routeId.isNullOrBlank()) View.GONE else View.VISIBLE

        val retry = root.findViewById<Button>(R.id.route_unavailable_retry)
        val update = root.findViewById<Button>(R.id.route_unavailable_update)
        val safeFallback = root.findViewById<Button>(R.id.route_unavailable_safe_fallback)

        bindActionButton(retry, RouteUnavailableAction.RETRY in denial.actions) {
            render(activationCoordinator.retry(), preserveCurrentRoute = false)
        }

        bindActionButton(update, RouteUnavailableAction.UPDATE_APP in denial.actions) {
            openUpdateApp()
        }

        bindActionButton(
            safeFallback,
            RouteUnavailableAction.SAFE_FALLBACK in denial.actions && denial.safeFallbackUrl != null
        ) {
            val safeUrl = denial.safeFallbackUrl ?: return@bindActionButton
            render(
                activationCoordinator.handleIntent(
                    Intent(Intent.ACTION_VIEW, Uri.parse(safeUrl)),
                    fallbackSource = ActivationSource.IN_APP_NAVIGATION
                ),
                preserveCurrentRoute = false
            )
        }
    }

    private fun bindActionButton(button: Button, enabled: Boolean, onClick: () -> Unit) {
        button.visibility = if (enabled) View.VISIBLE else View.GONE
        button.isEnabled = enabled
        button.setOnClickListener { onClick() }
    }

    private fun openUpdateApp() {
        val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName"))
        val webIntent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
        )

        runCatching { startActivity(marketIntent) }
            .getOrElse { startActivity(webIntent) }
    }

    companion object {
        private const val CONTAINER_ID = 1001
    }
}
