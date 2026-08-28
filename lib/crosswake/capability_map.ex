defmodule Crosswake.CapabilityMap do
  @moduledoc """
  Canonical capability-map truth for support posture, proof posture, and first adopter pressure.

  This module is intentionally small and data-oriented. It classifies current support,
  proof-backed evidence, first adopter pressure, and future gaps without
  adding native controls, provider adapters, storage/sync productization, or dashboard UI.
  """

  defmodule Row do
    @moduledoc false

    @enforce_keys [
      :id,
      :surface,
      :route_or_evidence_source,
      :category,
      :display_label,
      :route_runtime_owner,
      :package_owner,
      :proof_posture,
      :rebuild,
      :denial_fallback,
      :adoption_implication
    ]

    defstruct @enforce_keys

    @type t :: %__MODULE__{
            id: String.t(),
            surface: String.t(),
            route_or_evidence_source: String.t(),
            category: Crosswake.CapabilityMap.category(),
            display_label: String.t(),
            route_runtime_owner: Crosswake.CapabilityMap.route_runtime_owner(),
            package_owner: Crosswake.CapabilityMap.package_owner(),
            proof_posture: Crosswake.CapabilityMap.proof_posture(),
            rebuild: Crosswake.CapabilityMap.rebuild(),
            denial_fallback: String.t(),
            adoption_implication: String.t()
          }
  end

  @categories [:shipped, :demoed, :missing, :deferred, :next_pack_candidate]

  @display_labels [
    "Available today",
    "Proof-backed example",
    "Demo pressure",
    "Advisory evidence",
    "Future gap",
    "Next-pack candidate"
  ]

  @package_owners [:core, :native_shell, :first_party_companion, :example_docs_only, :deferred]
  @proof_postures [:merge_blocking, :advisory, :not_yet_proven, :unsupported]

  # D-53 (Phase 154, CTRL-05): mirrors Crosswake.Manifest.Types.Capability.rebuild/0's
  # three-value vocabulary — the guide adopters read to CHOOSE controls must show
  # rebuild cost, not just support posture. Rows without a live manifest capability
  # entry still declare an explicit value (never a placeholder), per the same
  # honesty discipline D-52 applies to the catalog itself.
  @rebuild_classes [:none, :native_required, :companion_required]

  @route_runtime_owners [
    :live_view,
    :bounded_bridge,
    :native_shell,
    :native_screen,
    :offline_island,
    :backend_projection,
    :future_native_control
  ]

  @type category :: :shipped | :demoed | :missing | :deferred | :next_pack_candidate

  @type package_owner ::
          :core | :native_shell | :first_party_companion | :example_docs_only | :deferred

  @type proof_posture :: :merge_blocking | :advisory | :not_yet_proven | :unsupported

  @type rebuild :: :none | :native_required | :companion_required

  @type route_runtime_owner ::
          :live_view
          | :bounded_bridge
          | :native_shell
          | :native_screen
          | :offline_island
          | :backend_projection
          | :future_native_control

  @spec categories() :: [category()]
  def categories, do: @categories

  @spec display_labels() :: [String.t()]
  def display_labels, do: @display_labels

  @spec package_owners() :: [package_owner()]
  def package_owners, do: @package_owners

  @spec proof_postures() :: [proof_posture()]
  def proof_postures, do: @proof_postures

  @spec rebuild_classes() :: [rebuild()]
  def rebuild_classes, do: @rebuild_classes

  @spec route_runtime_owners() :: [route_runtime_owner()]
  def route_runtime_owners, do: @route_runtime_owners

  @spec canonical() :: [Row.t()]
  def canonical do
    [
      row(
        id: "route-policy",
        surface: "Route policy DSL and runtime ownership",
        route_or_evidence_source: "guides/route_policy.md and compiled router metadata",
        category: :shipped,
        rebuild: :none,
        display_label: "Available today",
        route_runtime_owner: :live_view,
        package_owner: :core,
        proof_posture: :merge_blocking,
        denial_fallback:
          "Routes fail closed through explicit runtime policy, manifest validation, and support-matrix diagnostics.",
        adoption_implication:
          "Use as the explicit route-policy gate for the first adopter's proven mobile path."
      ),
      row(
        id: "deep-link-activation",
        surface: "Deep link and native shell activation",
        route_or_evidence_source: "guides/native_shell.md and bridge/native behavioral proof",
        category: :shipped,
        rebuild: :none,
        display_label: "Available today",
        route_runtime_owner: :native_shell,
        package_owner: :native_shell,
        proof_posture: :merge_blocking,
        denial_fallback:
          "Inactive or unsupported route entry falls back to route-unavailable guidance instead of hidden WebView navigation authority.",
        adoption_implication:
          "Keep activation truth at the shell boundary; do not infer route ownership from a wrapper."
      ),
      row(
        id: "bounded-bridge-app-info",
        surface: "Bounded bridge app info",
        route_or_evidence_source: "guides/bridge.md and manifest capability catalog",
        category: :shipped,
        rebuild: :none,
        display_label: "Available today",
        route_runtime_owner: :bounded_bridge,
        package_owner: :core,
        proof_posture: :merge_blocking,
        denial_fallback:
          "Phoenix route continues without native app metadata when the route has not declared the capability.",
        adoption_implication:
          "Retain only low-frequency request/reply contracts with explicit route-local ownership."
      ),
      row(
        id: "bounded-bridge-haptics",
        surface: "Bounded bridge haptics",
        route_or_evidence_source: "AdminPilot approval route and guides/bridge.md",
        category: :shipped,
        rebuild: :none,
        display_label: "Available today",
        route_runtime_owner: :bounded_bridge,
        package_owner: :core,
        proof_posture: :merge_blocking,
        denial_fallback:
          "Approval state remains Phoenix/server authoritative; haptics is optional confirmation feedback.",
        adoption_implication:
          "Keep as optional route-local feedback; it does not expand the first adopter's native breadth."
      ),
      row(
        id: "bounded-bridge-share",
        surface: "Bounded bridge share",
        route_or_evidence_source: "bridge-proof route and guides/capabilities.md",
        category: :demoed,
        rebuild: :none,
        display_label: "Advisory evidence",
        route_runtime_owner: :bounded_bridge,
        package_owner: :core,
        proof_posture: :advisory,
        denial_fallback:
          "Content stays in the Phoenix-owned route when a share family is undeclared or unavailable.",
        adoption_implication:
          "Keep advisory until a first adopter route supplies explicit platform support truth."
      ),
      row(
        id: "permissions-status",
        surface: "Read-only permission status",
        route_or_evidence_source: "permissions.status capability family",
        category: :shipped,
        rebuild: :none,
        display_label: "Available today",
        route_runtime_owner: :bounded_bridge,
        package_owner: :core,
        proof_posture: :merge_blocking,
        denial_fallback:
          "Route continues without native notification permission snapshot authority when undeclared.",
        adoption_implication:
          "Read-only snapshots may inform a route; permission requests remain outside the first adopter scope."
      ),
      row(
        id: "notification-token",
        surface: "Notification token evidence snapshot",
        route_or_evidence_source:
          "notification_token capability family and Chimeway support truth",
        category: :demoed,
        rebuild: :companion_required,
        display_label: "Advisory evidence",
        route_runtime_owner: :bounded_bridge,
        package_owner: :first_party_companion,
        proof_posture: :advisory,
        denial_fallback:
          "Token replies are provider-tagged evidence, not backend registration truth or delivery proof.",
        adoption_implication:
          "Provider snapshots remain advisory; delivery and universal notification handling stay outside core."
      ),
      row(
        id: "adminpilot-approval-haptics",
        surface: "AdminPilot approval haptics pressure",
        route_or_evidence_source: "/saas/approvals/approval-1 route-tour proof",
        category: :demoed,
        rebuild: :none,
        display_label: "Proof-backed example",
        route_runtime_owner: :bounded_bridge,
        package_owner: :core,
        proof_posture: :merge_blocking,
        denial_fallback:
          "Phoenix approval mutation commits server state first; native haptics can fail without changing approval authority.",
        adoption_implication:
          "Use only as route-local success-feedback evidence, not as a new control-program recommendation."
      ),
      row(
        id: "fieldserv-capture-handoff",
        surface: "Fieldserv native capture handoff",
        route_or_evidence_source: "/fieldserv/jobs/:id/capture handoff evidence",
        category: :next_pack_candidate,
        rebuild: :native_required,
        display_label: "Next-pack candidate",
        route_runtime_owner: :native_screen,
        package_owner: :native_shell,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "The host app owns this native screen; browser evidence review remains backend-verification truth.",
        adoption_implication: "Promote only after Capture & Device Controls proof exists."
      ),
      row(
        id: "fieldserv-scanner",
        surface: "Scanner and QR scan",
        route_or_evidence_source: "Fieldserv capability pressure rows",
        category: :missing,
        rebuild: :companion_required,
        display_label: "Future gap",
        route_runtime_owner: :future_native_control,
        package_owner: :deferred,
        proof_posture: :unsupported,
        denial_fallback:
          "Scanner requests remain unavailable instead of falling through to generic plugin support.",
        adoption_implication: "Defer to Capture & Device Controls."
      ),
      row(
        id: "fieldserv-document-scan",
        surface: "Document scan",
        route_or_evidence_source: "Fieldserv capability pressure rows",
        category: :missing,
        rebuild: :companion_required,
        display_label: "Future gap",
        route_runtime_owner: :future_native_control,
        package_owner: :deferred,
        proof_posture: :unsupported,
        denial_fallback:
          "Document scan stays unavailable until native session ownership and proof posture are explicit.",
        adoption_implication: "Defer to Capture & Device Controls."
      ),
      row(
        id: "fieldserv-media-upload",
        surface: "Media upload and evidence availability",
        route_or_evidence_source: "Fieldserv evidence review route",
        category: :missing,
        rebuild: :native_required,
        display_label: "Future gap",
        route_runtime_owner: :future_native_control,
        package_owner: :deferred,
        proof_posture: :unsupported,
        denial_fallback:
          "Backend verification, not device evidence, determines whether media evidence is available.",
        adoption_implication: "Defer to Capture & Device Controls."
      ),
      row(
        id: "fieldserv-offline-inspection",
        surface: "Offline field inspection mutation",
        route_or_evidence_source: "Fieldserv cached read-only posture",
        category: :deferred,
        rebuild: :none,
        display_label: "Future gap",
        route_runtime_owner: :future_native_control,
        package_owner: :deferred,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "Cached read-only remains explicit; local mutation needs a journal, outbox, retry, and reconciliation path.",
        adoption_implication: "Defer to Offline Sync/Native Storage Productization."
      ),
      row(
        id: "learnloop-offline-study",
        surface: "LearnLoop socketless offline study island",
        route_or_evidence_source: "/learnloop/study/session and offline route-tour proof",
        category: :demoed,
        rebuild: :none,
        display_label: "Proof-backed example",
        route_runtime_owner: :offline_island,
        package_owner: :example_docs_only,
        proof_posture: :merge_blocking,
        denial_fallback:
          "Browser-owned IndexedDB outbox and reconciliation visibility are local to the offline island; server reset does not clear browser-owned state.",
        adoption_implication:
          "Use as evidence for one route-local offline island, not a generic sync or storage claim."
      ),
      row(
        id: "learnloop-native-storage",
        surface: "Production iOS storage for offline pronunciation media",
        route_or_evidence_source: "First adopter offline pronunciation pressure",
        category: :deferred,
        rebuild: :native_required,
        display_label: "Future gap",
        route_runtime_owner: :future_native_control,
        package_owner: :deferred,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "Current native pack stores simulate lifecycle transitions; a pack must remain unavailable until a host provider verifies real bytes and installs them atomically.",
        adoption_implication:
          "v21 permits one host-supplied foreground iOS adapter. Generic native pack storage remains unclaimed."
      ),
      row(
        id: "learnloop-sync-productization",
        surface: "Reusable sync helpers",
        route_or_evidence_source: "LearnLoop replay and history diagnostics",
        category: :deferred,
        rebuild: :none,
        display_label: "Future gap",
        route_runtime_owner: :future_native_control,
        package_owner: :deferred,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "The example outbox proves one route-local flow, not a universal sync engine.",
        adoption_implication: "Defer to Offline Sync/Native Storage Productization."
      ),
      row(
        id: "learnloop-paywall-projection",
        surface: "Backend-owned mocked entitlement projection",
        route_or_evidence_source: "/learnloop/subscription and commerce guide",
        category: :demoed,
        rebuild: :companion_required,
        display_label: "Demo pressure",
        route_runtime_owner: :backend_projection,
        package_owner: :example_docs_only,
        proof_posture: :advisory,
        denial_fallback:
          "Backend projection remains entitlement authority; device or storefront evidence never grants access.",
        adoption_implication:
          "Keep commerce and provider support outside the first adopter's current infrastructure path."
      ),
      row(
        id: "commerce-provider-integration",
        surface: "StoreKit, Play Billing, and RevenueCat production integration",
        route_or_evidence_source: "guides/commerce.md and LearnLoop pressure",
        category: :deferred,
        rebuild: :native_required,
        display_label: "Future gap",
        route_runtime_owner: :backend_projection,
        package_owner: :deferred,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "Provider events are reconciliation evidence until backend projection grants entitlement authority.",
        adoption_implication: "Defer to Commerce/Paywall Productionization later."
      ),
      row(
        id: "first-adopter-host-proof",
        surface: "Host-reusable offline-island and shell proof scaffold",
        route_or_evidence_source: "Current example-host proof lane and first adopter test corpus",
        category: :missing,
        rebuild: :none,
        display_label: "Demo pressure",
        route_runtime_owner: :offline_island,
        package_owner: :core,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "Example-host proof remains valid, but no support claim transfers to an external host until that host can configure and run the lane.",
        adoption_implication:
          "Build host-reusable iOS proof before adding any native capability breadth."
      ),
      row(
        id: "first-adopter-scoped-replay",
        surface: "Privacy-safe scope-bound journal and replay",
        route_or_evidence_source: "First adopter free-form offline mutation pressure",
        category: :missing,
        rebuild: :none,
        display_label: "Demo pressure",
        route_runtime_owner: :offline_island,
        package_owner: :core,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "Replay stops on missing or mismatched scope, logout, account switch, failed authorization, or a disabled route; raw payload never becomes diagnostic evidence.",
        adoption_implication:
          "Require opaque scope references and redaction before any replay claim; keep payload semantics host-owned."
      ),
      row(
        id: "first-adopter-ios-navigation-shell",
        surface: "First adopter iOS native navigation shell",
        route_or_evidence_source:
          "bounded iOS-only compiled topology, typed stack protocol, UIKit host composition, marker/insets, and generated host proof",
        category: :demoed,
        rebuild: :native_required,
        display_label: "Advisory evidence",
        route_runtime_owner: :native_shell,
        package_owner: :native_shell,
        proof_posture: :advisory,
        denial_fallback:
          "No generic navigation, Android parity, native leaf rendering, arbitrary restoration, modal breadth, or browser-history authority is claimed; invalid input keeps the existing explicit Phoenix denial.",
        adoption_implication:
          "The bounded contract is advisory until a validated TODO-002 handoff and source-bound signed-device run compose it; simulator and fixture results remain non-promoting."
      ),
      row(
        id: "first-adopter-physical-iphone",
        surface: "Physical-iPhone offline study and replay evidence",
        route_or_evidence_source: "First adopter source-bound physical exit test",
        category: :missing,
        rebuild: :native_required,
        display_label: "Future gap",
        route_runtime_owner: :offline_island,
        package_owner: :native_shell,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "Simulator, generated-shell, browser, unit, and fixture evidence remain explicitly narrower than source-bound physical-device proof.",
        adoption_implication:
          "Support remains blocked until validated TODO-002 input and one signed iPhone complete the source-bound composed route, pack, replay, recovery, and evidence exit test."
      ),
      row(
        id: "native-controls-alert-confirm",
        surface: "Native alert and confirm affordances",
        route_or_evidence_source: "v20 Pack 1 candidate from v19 evidence",
        category: :next_pack_candidate,
        rebuild: :native_required,
        display_label: "Next-pack candidate",
        route_runtime_owner: :future_native_control,
        package_owner: :core,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "Until declared and proven, routes must keep Phoenix-owned confirmation surfaces.",
        adoption_implication:
          "Stopped for now; keep the Phoenix-owned fallback. Reconsider only after physical-iPhone proof, a demonstrated active-adopter route blocker, and an explicit maintainer roadmap decision."
      ),
      row(
        id: "native-controls-action-menu",
        surface: "Native menu and action-button affordances",
        route_or_evidence_source: "v20 Pack 1 candidate from AdminPilot and Fieldserv pressure",
        category: :next_pack_candidate,
        rebuild: :native_required,
        display_label: "Next-pack candidate",
        route_runtime_owner: :future_native_control,
        package_owner: :core,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "Actions remain Phoenix-owned until route policy, allowlists, and fallback behavior are explicit.",
        adoption_implication:
          "Stopped for now; native menu breadth does not unblock the first adopter."
      ),
      row(
        id: "native-controls-toast-review",
        surface: "Native toast and review prompt",
        route_or_evidence_source: "v20 Pack 1 candidate from showcase feedback pressure",
        category: :next_pack_candidate,
        rebuild: :native_required,
        display_label: "Next-pack candidate",
        route_runtime_owner: :future_native_control,
        package_owner: :core,
        proof_posture: :not_yet_proven,
        denial_fallback:
          "Routes must treat toast/review prompts as optional UX evidence, not navigation or backend authority.",
        adoption_implication:
          "Stopped for now; optional UX breadth follows physical-device adoption proof."
      )
    ]
  end

  defp row(attrs) do
    attrs
    |> Map.new()
    |> then(&struct!(Row, &1))
  end
end
