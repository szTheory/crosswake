package dev.crosswake.shell

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.FrameLayout
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import dev.crosswake.shell.core.*
import dev.crosswake.shell.packs.RequiredPackActivity

class MainActivity : AppCompatActivity(), LiveViewFragment.Host {
    lateinit var shell: CrosswakeShell
    private var filePickerCoordinator: FilePickerCoordinator? = null

    private val requiredPackLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        shell.handleIntent(intent)
    }

    private val nativeCaptureLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        shell.handleIntent(intent)
    }

    private val filePickerLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        filePickerCoordinator?.consumeResult(result.resultCode, result.data)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val config = CrosswakeShellConfig(
            appInfoDelegate = object : AppInfoDelegate {
                override fun getAppInfo(): Map<String, String> {
                    val packageManager = packageManager
                    val packageInfo = packageManager.getPackageInfo(packageName, 0)
                    return mapOf(
                        "version" to (packageInfo.versionName ?: ""),
                        "build" to if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                            packageInfo.longVersionCode.toString()
                        } else {
                            packageInfo.versionCode.toString()
                        },
                        "bundle_id" to packageName
                    )
                }
            },
            hapticsDelegate = object : HapticsDelegate {
                override fun impact(style: String) {
                    val feedbackConstant = when (style) {
                        "heavy" -> android.view.HapticFeedbackConstants.LONG_PRESS
                        "light" -> android.view.HapticFeedbackConstants.KEYBOARD_TAP
                        else -> android.view.HapticFeedbackConstants.VIRTUAL_KEY
                    }
                    window.decorView.performHapticFeedback(feedbackConstant)
                }
            },
            permissionStatusDelegate = object : PermissionStatusDelegate {
                override fun getStatus(alias: String): Map<String, String>? {
                    return PermissionStatusProvider(this@MainActivity).statusPayload(alias)
                }
            },
            notificationTokenDelegate = object : NotificationTokenDelegate {
                override fun fetch(): NotificationTokenDelegate.Result {
                    return NotificationTokenProvider(this@MainActivity).fetch()
                }
            },
            shareDelegate = object : ShareDelegate {
                override fun invoke(payload: Map<String, String>) {
                    val title = payload["title"] ?: ""
                    val text = payload["text"]
                    val url = payload["url"]
                    val combinedText = listOfNotNull(text, url).joinToString("\n")

                    val sendIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TITLE, title)
                        putExtra(Intent.EXTRA_TEXT, combinedText)
                    }
                    startActivity(Intent.createChooser(sendIntent, title))
                }
            },
            filesPickDelegate = object : FilesPickDelegate {
                override fun pick(payload: Map<String, String>, correlationId: String): FilesPickResult {
                    val coordinator = filePickerCoordinator
                        ?: return FilesPickResult.Denied(
                            reason = "undeclared_capability",
                            message = "This route does not declare the requested transfer seam.",
                            hint = "Retry only after mounting a LiveView session with a manifest-declared native_picker transfer."
                        )

                    return coordinator.pick(payload, correlationId)
                }
            }
        )

        shell = CrosswakeShell(this, config)

        DiagnosticExportManager.start(this, "https://api.example.com/diagnostics/export", "0.1.0")

        setContent {
            MaterialTheme {
                val state by shell.state.collectAsState()
                RenderPresentation(state)
            }
        }

        if (savedInstanceState == null) {
            shell.bootstrap(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        shell.handleIntent(intent)
    }

    override fun allowNavigation(url: String): Boolean {
        return when (val decision = shell.resolveNavigation(url)) {
            NavigationDecision.Allow -> true
            is NavigationDecision.Deny -> {
                false
            }
        }
    }

    override fun filesPick(payload: Map<String, String>, correlationId: String): FilesPickResult {
        return shell.config.filesPickDelegate?.pick(payload, correlationId) ?: FilesPickResult.Denied("unavailable", "unavailable", "unavailable")
    }

    @Composable
    private fun RenderPresentation(presentation: ShellPresentation) {
        when (presentation) {
            is ShellPresentation.Booting -> {
                RouteUnavailableScreen(
                    RouteDenialPresentation(
                        reason = RouteDenialReason.COMPATIBILITY_MISMATCH,
                        title = "Shell boot blocked",
                        message = "Crosswake could not resolve a manifest-first activation request.",
                        hint = "Retry after confirming bundled fixtures are present.",
                        routeId = null,
                        actions = listOf(RouteUnavailableAction.RETRY),
                        safeFallbackUrl = null
                    )
                )
            }
            is ShellPresentation.RequiredPack -> {
                LaunchedEffect(presentation) {
                    showRequiredPack(presentation.requiredPack)
                }
            }
            is ShellPresentation.NativeCapture -> {
                LaunchedEffect(presentation) {
                    showNativeCapture(presentation.nativeCapture)
                }
            }
            is ShellPresentation.Denied -> {
                RouteUnavailableScreen(presentation.denial)
            }
            is ShellPresentation.LiveView -> {
                LiveViewScreen(presentation.session)
            }
        }
    }

    @Composable
    private fun RouteUnavailableScreen(denial: RouteDenialPresentation) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = denial.title, style = MaterialTheme.typography.headlineMedium)
            Spacer(modifier = Modifier.height(8.dp))
            Text(text = denial.message, style = MaterialTheme.typography.bodyLarge)
            Spacer(modifier = Modifier.height(8.dp))
            Text(text = "Reason: ${denial.reason.wireValue}", style = MaterialTheme.typography.bodyMedium)
            
            denial.hint?.let {
                Spacer(modifier = Modifier.height(8.dp))
                Text(text = it, style = MaterialTheme.typography.bodySmall)
            }

            Spacer(modifier = Modifier.height(16.dp))
            if (RouteUnavailableAction.RETRY in denial.actions) {
                Button(onClick = { shell.retry() }) {
                    Text("Retry")
                }
            }
            if (RouteUnavailableAction.UPDATE_APP in denial.actions) {
                Button(onClick = { openUpdateApp() }) {
                    Text("Update App")
                }
            }
            if (RouteUnavailableAction.SAFE_FALLBACK in denial.actions && denial.safeFallbackUrl != null) {
                Button(onClick = {
                    shell.handleIntent(Intent(Intent.ACTION_VIEW, Uri.parse(denial.safeFallbackUrl)))
                }) {
                    Text("Open Fallback")
                }
            }
        }
    }

    @Composable
    private fun LiveViewScreen(session: LiveViewSession) {
        AndroidView(
            factory = { context ->
                val frame = FrameLayout(context).apply {
                    id = CONTAINER_ID
                    ViewCompat.setOnApplyWindowInsetsListener(this) { view, insets ->
                        val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
                        view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
                        insets
                    }
                }
                
                val fragmentManager = (context as AppCompatActivity).supportFragmentManager
                val existing = fragmentManager.findFragmentByTag(LiveViewFragment.TAG) as? LiveViewFragment
                if (existing?.represents(session) != true) {
                    fragmentManager.beginTransaction()
                        .replace(CONTAINER_ID, LiveViewFragment.newInstance(session), LiveViewFragment.TAG)
                        .commitAllowingStateLoss()
                }
                
                frame
            },
            update = { frame ->
                val fragmentManager = (frame.context as AppCompatActivity).supportFragmentManager
                val existing = fragmentManager.findFragmentByTag(LiveViewFragment.TAG) as? LiveViewFragment
                if (existing?.represents(session) != true) {
                    fragmentManager.beginTransaction()
                        .replace(CONTAINER_ID, LiveViewFragment.newInstance(session), LiveViewFragment.TAG)
                        .commitAllowingStateLoss()
                }
            }
        )

        DisposableEffect(session) {
            filePickerCoordinator = shell.currentTransferCoordinator?.let { transferCoordinator ->
                FilePickerCoordinator(
                    context = this@MainActivity,
                    transferCoordinator = transferCoordinator,
                    launchPicker = filePickerLauncher::launch
                )
            }
            onDispose {
                filePickerCoordinator = null
            }
        }
    }

    private fun showRequiredPack(requiredPack: RequiredPackPresentation) {
        filePickerCoordinator = null
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
