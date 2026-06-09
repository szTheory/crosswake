package dev.crosswake.shell

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.fragment.app.Fragment
import dev.crosswake.shell.transfer.TransferCoordinator
import org.json.JSONArray
import org.json.JSONObject

class LiveViewFragment : Fragment() {
    interface Host {
        val shell: CrosswakeShell
        fun allowNavigation(url: String): Boolean
        fun filesPick(payload: Map<String, String>, correlationId: String): FilesPickResult
    }

    private val session: LiveViewSession
        get() = LiveViewSession(
            routeId = requireArguments().getString(ARG_ROUTE_ID).orEmpty(),
            url = requireArguments().getString(ARG_URL).orEmpty(),
            allowedOrigin = requireArguments().getString(ARG_ALLOWED_ORIGIN).orEmpty(),
            bridgeProtocolVersion = requireArguments().getString(ARG_BRIDGE_PROTOCOL_VERSION).orEmpty(),
            nativeRuntimeVersion = requireArguments().getString(ARG_NATIVE_RUNTIME_VERSION).orEmpty(),
            installedPacks = requireArguments().getSerializable(ARG_INSTALLED_PACKS) as? Map<String, String> ?: emptyMap(),
            routeRequiredPacks = requireArguments().getStringArrayList(ARG_ROUTE_REQUIRED_PACKS)?.toList() ?: emptyList(),
            capabilities = requireArguments().getSerializable(ARG_CAPABILITIES) as? Map<String, String> ?: emptyMap(),
            declaredTransfers = transferSeamsFromJson(requireArguments().getString(ARG_DECLARED_TRANSFERS))
        )

    private val transferCoordinator: TransferCoordinator
        get() = TransferCoordinator(
            routeId = session.routeId,
            declaredTransfers = session.declaredTransfers
        )

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return WebView(requireContext())
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        configureWebView(view as WebView)
        loadRouteIfNeeded(view)
    }

    fun represents(candidate: LiveViewSession): Boolean {
        return session == candidate
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun configureWebView(webView: WebView) {
        webView.id = WEB_VIEW_ID
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.settings.allowFileAccess = false
        webView.settings.allowContentAccess = false
        webView.settings.setSupportZoom(false)
        WebView.setWebContentsDebuggingEnabled(false)

        val host = activity as? Host
        val bridgeChannel = host?.shell?.createBridgeChannel(
            session = session,
            transferCoordinator = transferCoordinator
        ) ?: throw IllegalStateException("LiveViewFragment must be attached to a Host that provides a CrosswakeShell instance")

        bridgeChannel.attach(webView, setOf(session.allowedOrigin))
        
        val capabilities = host?.shell?.config?.registeredCapabilities ?: emptyList()
        val capabilitiesJson = org.json.JSONArray(capabilities).toString()

        if (WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)) {
            WebViewCompat.addDocumentStartJavaScript(
                webView,
                """
                window.crosswakeBridge = window.crosswakeBridge || {};
                window.crosswakeBridge.capabilities = $capabilitiesJson;
                window.crosswakeBridge.threadId = "${session.threadId}";
                """.trimIndent(),
                setOf("*")
            )
        }

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                val target = request.url.toString()

                // Allowlisted same-origin routes stay under native activation authority.
                return if ((activity as? Host)?.allowNavigation(target) == true) {
                    false
                } else {
                    true
                }
            }

            override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                super.onPageStarted(view, url, favicon)
            }
        }
    }

    private fun loadRouteIfNeeded(webView: WebView) {
        if (!isSameOrigin(session.url, session.allowedOrigin)) {
            (activity as? Host)?.allowNavigation(session.url)
            return
        }

        webView.loadUrl(session.url)
    }

    companion object {
        const val TAG = "crosswake-live-view"
        const val WEB_VIEW_ID = 1002

        private const val ARG_ROUTE_ID = "route_id"
        private const val ARG_URL = "url"
        private const val ARG_ALLOWED_ORIGIN = "allowed_origin"
        private const val ARG_BRIDGE_PROTOCOL_VERSION = "bridge_protocol_version"
        private const val ARG_NATIVE_RUNTIME_VERSION = "native_runtime_version"
        private const val ARG_INSTALLED_PACKS = "installed_packs"
        private const val ARG_ROUTE_REQUIRED_PACKS = "route_required_packs"
        private const val ARG_CAPABILITIES = "capabilities"
        private const val ARG_DECLARED_TRANSFERS = "declared_transfers"

        fun newInstance(session: LiveViewSession): LiveViewFragment {
            return LiveViewFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_ROUTE_ID, session.routeId)
                    putString(ARG_URL, session.url)
                    putString(ARG_ALLOWED_ORIGIN, session.allowedOrigin)
                    putString(ARG_BRIDGE_PROTOCOL_VERSION, session.bridgeProtocolVersion)
                    putString(ARG_NATIVE_RUNTIME_VERSION, session.nativeRuntimeVersion)
                    putSerializable(ARG_INSTALLED_PACKS, HashMap(session.installedPacks))
                    putStringArrayList(ARG_ROUTE_REQUIRED_PACKS, ArrayList(session.routeRequiredPacks))
                    putSerializable(ARG_CAPABILITIES, HashMap(session.capabilities))
                    putString(ARG_DECLARED_TRANSFERS, transferSeamsToJson(session.declaredTransfers))
                }
            }
        }

        fun isSameOrigin(url: String, allowedOrigin: String): Boolean {
            return ActivationRequest.originFromUrl(url) == allowedOrigin
        }

        private fun transferSeamsToJson(transfers: List<ShellManifest.TransferSeam>): String {
            return JSONArray(
                transfers.map { transfer ->
                    JSONObject()
                        .put("id", transfer.id)
                        .put("intent", transfer.intent)
                        .put("direction", transfer.direction)
                        .put("source", transfer.source)
                        .put("destination", transfer.destination)
                        .put("verification", transfer.verification)
                        .put("media_types", JSONArray(transfer.mediaTypes))
                        .put("states", JSONArray(transfer.states))
                }
            ).toString()
        }

        private fun transferSeamsFromJson(json: String?): List<ShellManifest.TransferSeam> {
            if (json.isNullOrBlank()) {
                return emptyList()
            }

            val array = JSONArray(json)

            return List(array.length()) { index ->
                val transfer = array.getJSONObject(index)

                ShellManifest.TransferSeam(
                    id = transfer.getString("id"),
                    intent = transfer.getString("intent"),
                    direction = transfer.getString("direction"),
                    source = transfer.optString("source").takeIf { it.isNotBlank() },
                    destination = transfer.optString("destination").takeIf { it.isNotBlank() },
                    verification = transfer.getString("verification"),
                    mediaTypes = transfer.getJSONArray("media_types").toStringList(),
                    states = transfer.getJSONArray("states").toStringList()
                )
            }
        }

        private fun JSONArray.toStringList(): List<String> {
            return List(length()) { index -> getString(index) }
        }
    }
}
