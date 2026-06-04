defmodule Crosswake.SupportMatrix do
  @moduledoc """
  Canonical support-matrix truth shared across manifest generation, doctor, and docs.
  """

  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.CapabilitySupportEntry
  alias Crosswake.Manifest.Types.ChangeClassEntry
  alias Crosswake.Manifest.Types.PackageSurfaceEntry
  alias Crosswake.Manifest.Types.ReleaseBoundaryEntry
  alias Crosswake.Manifest.Types.RuntimeLineRow
  alias Crosswake.Manifest.Types.SupportEntry
  alias Crosswake.Manifest.Types.SupportMatrix
  alias Crosswake.Companions.Sigra.Telemetry, as: SigraTelemetry

  @statuses [:supported, :verification_required, :unsupported]
  @proof_classes [:merge_blocking, :advisory, :not_applicable]
  @diagnostic_severities [:error, :warning, :advisory]
  @commerce_corridor_prerequisite_taxonomy [
    :route_declaration,
    :backend_reconciliation,
    :native_adapter,
    :provider_setup
  ]
  @commerce_corridor_entries [
    %{
      corridor_role: "paywall_entry",
      owner_posture: "phoenix_owned",
      prerequisite_classes: [:route_declaration, :backend_reconciliation],
      prerequisites: [
        "route declares commerce corridor binding",
        "backend entitlement contract available"
      ],
      denial_codes: [
        "commerce.corridor.undeclared",
        "commerce.corridor.entry_denied",
        "commerce.corridor.origin_denied"
      ],
      fallback_behavior:
        "Keep the paywall route Phoenix-owned and return explicit declaration guidance when a corridor check fails.",
      native_rebuild_required: false,
      rebuild_requirement: %{
        native_rebuild_required: false,
        rebuild_trigger:
          "Core route/manifest metadata only — Phoenix-owned paywall changes do not require a native shell rebuild."
      },
      proof_class: :merge_blocking,
      advisory_provider_proof: false
    },
    %{
      corridor_role: "account_management",
      owner_posture: "phoenix_owned",
      prerequisite_classes: [:route_declaration, :backend_reconciliation],
      prerequisites: [
        "route declares commerce corridor binding",
        "backend entitlement projection available"
      ],
      denial_codes: [
        "commerce.corridor.undeclared",
        "commerce.corridor.policy_blocked",
        "commerce.corridor.prerequisite_missing"
      ],
      fallback_behavior:
        "Return to backend-owned account management guidance and fail closed until prerequisites are restored.",
      native_rebuild_required: false,
      rebuild_requirement: %{
        native_rebuild_required: false,
        rebuild_trigger:
          "Core route/manifest metadata only — backend-owned account surfaces do not require a native shell rebuild."
      },
      proof_class: :merge_blocking,
      advisory_provider_proof: false
    },
    %{
      corridor_role: "purchase_intent",
      owner_posture: "native_or_companion_required",
      prerequisite_classes: [:native_adapter, :provider_setup, :backend_reconciliation],
      prerequisites: [
        "native or companion storefront corridor implemented",
        "backend reconciliation ingest enabled"
      ],
      denial_codes: [
        "commerce.corridor.runtime_incompatible",
        "commerce.corridor.unsupported",
        "commerce.corridor.pack_incompatible",
        "commerce.corridor.prerequisite_missing"
      ],
      fallback_behavior:
        "Fail closed with return-to-Phoenix guidance; never grant entitlement authority from device intent alone.",
      native_rebuild_required: true,
      rebuild_requirement: %{
        native_rebuild_required: true,
        rebuild_trigger:
          "Native adapter or provider SDK code changes require rebuilding and resubmitting the host shell."
      },
      proof_class: :merge_blocking,
      advisory_provider_proof: true
    },
    %{
      corridor_role: "restore_intent",
      owner_posture: "native_or_companion_required",
      prerequisite_classes: [:native_adapter, :provider_setup, :backend_reconciliation],
      prerequisites: [
        "native or companion restore corridor implemented",
        "backend reconciliation ingest enabled"
      ],
      denial_codes: [
        "commerce.corridor.runtime_incompatible",
        "commerce.corridor.unsupported",
        "commerce.corridor.pack_incompatible",
        "commerce.corridor.prerequisite_missing"
      ],
      fallback_behavior:
        "Fail closed with restore guidance and keep entitlement truth backend-owned until evidence is reconciled.",
      native_rebuild_required: true,
      rebuild_requirement: %{
        native_rebuild_required: true,
        rebuild_trigger:
          "Native restore choreography or provider SDK code changes require rebuilding and resubmitting the host shell."
      },
      proof_class: :merge_blocking,
      advisory_provider_proof: true
    }
  ]
  @auth_contract_truth [
    %{
      surface:
        "Sigra SessionAuthorityLane route authority evaluator, handoff contract, step-up ceremony, and auth-return boundaries",
      owner: :backend_seam,
      package_class: :companion,
      proof_class: :merge_blocking,
      shipped_contracts: [
        :session_authority,
        :handoff_ticket,
        :server_record_redemption,
        :step_up_intent,
        :plug_liveview_ceremony,
        :auth_return_boundary,
        :auth_return_attempt
      ],
      handoff: %{
        status: :shipped,
        authority_source: :server_record,
        envelope_authority: false,
        audit_fields: [
          :event_id,
          :event_type,
          :handoff_ref,
          :state_before,
          :state_after,
          :outcome,
          :denial_code,
          :occurred_at,
          :route_id,
          :intent_kind,
          :source_session_ref,
          :projected_session_ref,
          :session_version_before,
          :session_version_after,
          :assurance_after,
          :auth_methods_after,
          :binding_result,
          :request_ref,
          :actor_kind
        ],
        proof_class: :merge_blocking
      },
      step_up: %{
        status: :shipped,
        authority_source: :server_record,
        locator_authority: false,
        lifecycle_states: [:issued, :challenged, :consumed, :expired, :canceled, :revoked],
        challenge_kinds: [:host_confirm_password],
        route_target_validation: :manifest_route_id,
        session_renewal: :host_instructions,
        csrf_rotation: :host_instruction,
        liveview_invalidation: :required,
        proof_class: :merge_blocking
      },
      auth_return: %{
        status: :shipped,
        authority_source: :server_record,
        envelope_authority: false,
        route_policy_seam: :auth_return,
        kinds: [:oauth, :passkey, :native_auth],
        transports: [:http_callback, :verified_https_link, :custom_scheme, :bridge_event],
        sensitive_transport: :verified_https_link_required,
        custom_scheme_posture: :advisory_only,
        route_target_validation: :manifest_route_id,
        proof_class: :merge_blocking
      },
      route_predicates: [:auth_min_level, :requires_recent_auth, :auth_posture],
      contract_surface: :full_sigra_machinery,
      contract_proof_class: :merge_blocking,
      route_authority_source: :session_authority_lane,
      evidence_authority: %{
        handoff_envelope: false,
        step_up_locator: false,
        auth_return_envelope: false,
        deep_link: false,
        bridge_event: false,
        provider_payload: false
      },
      host_readiness: :verification_required,
      provider_device_proof: :advisory,
      telemetry: %{
        status: :shipped,
        event_names: SigraTelemetry.event_names(),
        metadata_keys: SigraTelemetry.metadata_keys(),
        forbidden_metadata_keys: SigraTelemetry.forbidden_metadata_keys(),
        authority_source: :diagnostic_evidence_only,
        proof_class: :merge_blocking
      },
      security_closeout: %{
        status: :shipped,
        artifact: ".planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md",
        review_model: :stride,
        proof_class: :merge_blocking,
        unresolved_high_or_critical_findings: 0
      },
      denial_vocabulary: :step_up_required,
      denial_codes: Crosswake.Companions.Sigra.DenialCodes.codes(),
      safe_detail_keys: Crosswake.Companions.Sigra.DenialCodes.allowed_detail_keys(),
      fallback: :step_up_required,
      deferred: [
        :refresh_tokens,
        :native_auth_ui,
        :provider_device_proof
      ],
      posture:
        "Phase 58 Sigra posture: backend-owned SessionAuthorityLane route evaluation, shipped short-lived handoff ticket/server-record redemption, shipped server-owned step-up intent plus shared Plug/LiveView ceremony proof, shipped OAuth/passkey/native auth-return boundary contracts, stable low-cardinality auth telemetry, and dedicated security closeout. Handoff envelopes, step-up locators, OAuth/passkey/native return envelopes, deep links, bridge events, provider payloads, and telemetry are evidence only; server records, audit evidence, and refreshed SessionAuthorityLane projections remain authoritative. Refresh-token helpers, provider/device proof, provider templates, passkey SDK wrappers, direct shell/WebView token authority, and native auth UI remain deferred."
    }
  ]
  @companion_support_truth [
    %{
      surface:
        "Sigra session-authority route evaluator, handoff contract, step-up ceremony, and auth-return boundaries",
      proof_class: :merge_blocking,
      action_class: "companion_native",
      docs_anchor: "guides/companions.md#sigra-surface-auth-session-authority",
      deferred: [
        :refresh_tokens,
        :native_auth_ui,
        :provider_device_proof
      ],
      posture:
        "Sigra support includes backend session-authority contracts, auth_posture route truth, fail-closed step_up_required denial codes, shipped handoff ticket/server-record contracts, shipped step-up intent plus Plug/LiveView ceremony proof, shipped OAuth/passkey/native auth-return boundary contracts, stable auth telemetry, and security closeout; refresh tokens, provider/device proof, provider templates, passkey SDK wrappers, direct shell/WebView token authority, and native auth UI remain deferred."
    }
  ]
  @notification_support_truth [
    %{
      surface: "notification_token provider snapshot",
      proof_class: :advisory,
      action_class: "companion_native",
      docs_anchor: "guides/capabilities.md#bounded-bridge",
      delivery_supported: false,
      telemetry: %{
        status: :shipped,
        event_names: Crosswake.Companions.Chimeway.Telemetry.event_names(),
        metadata_keys: Crosswake.Companions.Chimeway.Telemetry.metadata_keys(),
        forbidden_metadata_keys: Crosswake.Companions.Chimeway.Telemetry.forbidden_metadata_keys(),
        authority_source: :diagnostic_evidence_only,
        proof_class: :merge_blocking
      },
      deferred: [:chimeway_delivery, :push_delivery_guarantees],
      posture:
        "notification_token and notification_open readiness are fully supported/resolvable; Chimeway APNs/FCM push delivery execution remains deferred and unsupported."
    }
  ]
  @diagnostic_export_support_truth [
    %{
      surface: "diagnostic export envelope contract",
      proof_class: :merge_blocking,
      action_class: "native_shell",
      docs_anchor: "guides/capabilities.md#diagnostic-export",
      delivery_supported: false,
      telemetry: %{
        status: :shipped,
        event_names: [],
        metadata_keys: Crosswake.Shell.DiagnosticExport.allowed_keys(),
        forbidden_metadata_keys: Crosswake.Shell.DiagnosticExport.forbidden_keys(),
        authority_source: :host_configured_endpoint,
        proof_class: :merge_blocking
      },
      deferred: [:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture],
      posture:
        "Diagnostics-export envelope and sanitize contract are shipped and merge-blocking allowlist proof is enforced; native MetricKit/ApplicationExitInfo transport is not shipped until Phase 67; the host owns the endpoint and the data — Crosswake is not a crash-reporting service."
    }
  ]

  # Rebuild & compatibility matrix rows — one row per major runtime-line band (D-14).
  # evidence_tier reuses the D-09 verification_method enum (D-15) — no separate enum.
  # ota_safe/rebuild_required are derived from RebuildPolicy/action_classes() co-truth:
  # rebuild-required bands are never OTA-safe.
  @rebuild_matrix_rows [
    Types.new_runtime_line_row(
      runtime_line: "1.x",
      capability_surface: [
        "haptics",
        "share",
        "app_info",
        "deep_link",
        "permissions.status",
        "notification_token",
        "file_picker",
        "media_capture",
        "scanner",
        "document_scan"
      ],
      change_class: "native or companion rebuild required",
      ota_safe: false,
      rebuild_required: true,
      evidence_tier: :jvm_hermetic
    ),
  ]

  @spec canonical(keyword()) :: SupportMatrix.t()
  def canonical(opts \\ []) do
    capability_registry =
      Keyword.get_lazy(opts, :capability_registry, fn ->
        Crosswake.Manifest.Builder.capability_registry([])
      end)

    Types.new_support_matrix(
      phoenix: [
        support_entry("phoenix", Keyword.get(opts, :phoenix_version, "~> 1.8"), :supported,
          proof: "phase-2-proof-lane",
          notes: "Phoenix host install and manifest generation are the stable baseline."
        )
      ],
      live_view: [
        support_entry(
          "phoenix_live_view",
          Keyword.get(opts, :live_view_version, "~> 1.1"),
          :supported,
          proof: "phase-2-proof-lane",
          notes: "LiveView remains server-owned and route-first.",
          boundary_link: "guides/offline.md#boundary-warnings--rough-edges"
        )
      ],
      ios: [
        support_entry("ios", Keyword.get(opts, :ios_version, "17.0"), :supported,
          baseline_status: :supported,
          proof_status: :supported,
          proof: "script/verify_generated_ios_shell.sh",
          notes:
            "Host-owned iOS shell boot is proof-backed by the checked-in example host and generated-shell verification hook.",
          boundary_link: "guides/native_shell.md#boundary-warnings--rough-edges"
        )
      ],
      android: [
        support_entry(
          "android",
          Keyword.get(opts, :android_version, "26"),
          :verification_required,
          baseline_status: :supported,
          proof_status: :verification_required,
          proof: "script/verify_generated_android_shell.sh",
          notes:
            "Host-owned Android shell boot is baseline-supported, but the current repository truth still requires the Java-enabled BridgeChannel proof lane to pass before Android support can be claimed as fully verified.",
          boundary_link: "guides/native_shell.md#boundary-warnings--rough-edges"
        )
      ],
      shells: [
        support_entry("ios_shell", Keyword.get(opts, :ios_shell_version, "0.1.0"), :supported,
          baseline_status: :supported,
          proof_status: :supported,
          proof: "script/verify_generated_ios_shell.sh",
          notes:
            "Generated iOS shell artifacts are supported while the Phase 5 iOS verification hook stays green.",
          boundary_link: "guides/native_shell.md#boundary-warnings--rough-edges"
        ),
        support_entry(
          "android_shell",
          Keyword.get(opts, :android_shell_version, "0.1.0"),
          :verification_required,
          baseline_status: :supported,
          proof_status: :verification_required,
          proof: "script/verify_generated_android_shell.sh",
          notes:
            "Generated Android shell artifacts remain baseline-supported, but repository support truth stays verification-required until the Java-enabled BridgeChannel proof lane passes.",
          boundary_link: "guides/native_shell.md#boundary-warnings--rough-edges"
        )
      ],
      capability_families: capability_family_entries(capability_registry),
      package_surfaces: package_surface_entries(),
      release_boundaries: release_boundary_entries(),
      change_classes: change_class_entries(),
      rebuild_matrix: @rebuild_matrix_rows
    )
  end

  @spec validate(SupportMatrix.t()) :: [map()]
  def validate(%SupportMatrix{} = support_matrix) do
    []
    |> validate_categories_present(support_matrix)
    |> validate_exact_statuses(support_matrix)
    |> validate_narrow_baseline(support_matrix)
    |> validate_capability_families_present(support_matrix)
    |> validate_phase51_support_truth()
    |> validate_verification_method_invariant(support_matrix)
    |> validate_rebuild_matrix_evidence(support_matrix)
  end

  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  @spec proof_classes() :: [atom()]
  def proof_classes, do: @proof_classes

  @spec diagnostic_severities() :: [atom()]
  def diagnostic_severities, do: @diagnostic_severities

  @spec action_classes() :: [Types.ActionClassEntry.t()]
  def action_classes, do: action_class_entries()

  @spec promotion_rules() :: [Types.PromotionRuleEntry.t()]
  def promotion_rules, do: promotion_rule_entries()

  @spec companion_support_truth() :: [map()]
  def companion_support_truth, do: @companion_support_truth

  @spec notification_support_truth() :: [map()]
  def notification_support_truth, do: @notification_support_truth

  @spec diagnostic_export_support_truth() :: [map()]
  def diagnostic_export_support_truth, do: @diagnostic_export_support_truth

  @spec fetch_status(SupportMatrix.t(), atom(), String.t()) ::
          {:ok, SupportEntry.status()} | :error
  def fetch_status(%SupportMatrix{} = support_matrix, category, version) when is_atom(category) do
    support_matrix
    |> Map.fetch!(category)
    |> Enum.find_value(:error, fn
      %SupportEntry{version: ^version, status: status} -> {:ok, status}
      _other -> nil
    end)
  end

  @spec capability_families(SupportMatrix.t()) :: [CapabilitySupportEntry.t()]
  def capability_families(%SupportMatrix{} = support_matrix),
    do: support_matrix.capability_families

  @spec rebuild_matrix(SupportMatrix.t()) :: [RuntimeLineRow.t()]
  def rebuild_matrix(%SupportMatrix{} = support_matrix),
    do: support_matrix.rebuild_matrix

  @spec package_surfaces(SupportMatrix.t()) :: [PackageSurfaceEntry.t()]
  def package_surfaces(%SupportMatrix{} = support_matrix), do: support_matrix.package_surfaces

  @spec release_boundaries(SupportMatrix.t()) :: [ReleaseBoundaryEntry.t()]
  def release_boundaries(%SupportMatrix{} = support_matrix), do: support_matrix.release_boundaries

  @spec change_classes(SupportMatrix.t()) :: [ChangeClassEntry.t()]
  def change_classes(%SupportMatrix{} = support_matrix), do: support_matrix.change_classes

  @doc """
  Runtime gate-state label.

  Returns the column label for the gating-truth section of the support matrix,
  deliberately runtime-distinct from build-proof posture. This label must never be
  misread as "supported" — a route in "rolling_out (10%)" state is gated, not
  supported, and the column label makes that explicit.

  D-08: "Runtime Gate State — not build-proof posture."
  """
  @spec gating_truth_label() :: String.t()
  def gating_truth_label, do: "Runtime Gate State — not build-proof posture"

  @doc """
  Returns a runtime snapshot of gate state for every registered companion.

  Reads `Application.get_env(:crosswake, :companions, [])` at call time (NOT
  compile_env) so test fixtures can register companions via `Application.put_env/3`
  and production callers see live runtime-registered companions.

  Each entry is a map with:
    - `:companion_id` — the atom id from `companion.companion_id()`
    - `:gate_state` — one of `"gated"`, `"rolling_out (N%)"`, `"killed"`, or `nil`
      (nil means the companion's gate is inactive or unconfigured)

  Kill-switch status overrides gate_status — if the kill switch is active,
  the entry shows `"killed"` regardless of `gate_status`.

  The `:gate_state` values are D-08 locked display strings. `"rolling_out (N%)"` is
  never equivalent to "supported" — the gating_truth_label/0 column heading
  reinforces this distinction.
  """
  @spec gating_truth() :: [map()]
  def gating_truth do
    Application.get_env(:crosswake, :companions, [])
    |> Enum.map(fn companion ->
      state = companion.report_state()
      %{companion_id: state.companion_id, gate_state: gate_state_display(state)}
    end)
  end

  @spec commerce_corridors() :: [map()]
  def commerce_corridors, do: @commerce_corridor_entries

  @spec auth_contract_truth() :: [map()]
  def auth_contract_truth, do: @auth_contract_truth

  @spec commerce_corridor_denial_codes() :: [String.t()]
  def commerce_corridor_denial_codes do
    @commerce_corridor_entries
    |> Enum.flat_map(& &1.denial_codes)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Returns the canonical taxonomy of prerequisite classes that may be referenced by
  commerce corridor entries. Every `prerequisite_classes` value on a commerce corridor
  entry must be drawn from this set so doctor/support/guides taxonomy stays parity-locked.
  """
  @spec commerce_corridor_prerequisite_taxonomy() :: [atom()]
  def commerce_corridor_prerequisite_taxonomy, do: @commerce_corridor_prerequisite_taxonomy

  @doc """
  Returns the canonical commerce corridor proof-class mapping.

  Every commerce corridor declares whether its hermetic Phoenix-owned contract proof is
  `:merge_blocking` (core route/manifest/denial truth that must pass before merge) and
  whether it also carries an `advisory_provider_proof` flag for storefront/simulator
  evidence (StoreKit, Play Billing) that stays advisory in v3.2.
  """
  @spec commerce_corridor_proof_classes() :: %{
          required(String.t()) => %{
            required(:proof_class) => :merge_blocking | :advisory,
            required(:advisory_provider_proof) => boolean()
          }
        }
  def commerce_corridor_proof_classes do
    Map.new(@commerce_corridor_entries, fn entry ->
      {entry.corridor_role,
       %{
         proof_class: entry.proof_class,
         advisory_provider_proof: entry.advisory_provider_proof
       }}
    end)
  end

  defp validate_categories_present(errors, %SupportMatrix{} = support_matrix) do
    Enum.reduce([:phoenix, :live_view, :ios, :android, :shells], errors, fn category, acc ->
      if Map.get(support_matrix, category, []) == [] do
        [
          %{
            key: category,
            message: "support matrix is missing #{category} baseline entries",
            hint: "add at least one #{category} entry to the canonical support matrix"
          }
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_exact_statuses(errors, %SupportMatrix{} = support_matrix) do
    support_matrix
    |> categories()
    |> Enum.reduce(errors, fn {category, entries}, acc ->
      Enum.reduce(entries, acc, fn %SupportEntry{status: status} = entry, inner_acc ->
        if status in @statuses do
          inner_acc
        else
          [
            %{
              key: category,
              message:
                "support entry #{entry.target}@#{entry.version} uses unsupported status #{inspect(status)}",
              hint: "use exactly :supported, :verification_required, or :unsupported"
            }
            | inner_acc
          ]
        end
      end)
    end)
  end

  defp validate_narrow_baseline(errors, %SupportMatrix{} = support_matrix) do
    counts = %{
      phoenix: 1,
      live_view: 1,
      ios: 1,
      android: 1,
      shells: 2
    }

    Enum.reduce(counts, errors, fn {category, expected_count}, acc ->
      actual_count = support_matrix |> Map.fetch!(category) |> length()

      if actual_count == expected_count do
        acc
      else
        [
          %{
            key: category,
            message:
              "support matrix for #{category} must stay narrow and proof-oriented (expected #{expected_count}, got #{actual_count})",
            hint:
              "keep the first public support matrix to one active Phoenix line, one LiveView line, one iOS floor, one Android floor, and two exact shell artifact entries"
          }
          | acc
        ]
      end
    end)
  end

  defp categories(%SupportMatrix{} = support_matrix) do
    [
      {:phoenix, support_matrix.phoenix},
      {:live_view, support_matrix.live_view},
      {:ios, support_matrix.ios},
      {:android, support_matrix.android},
      {:shells, support_matrix.shells}
    ]
  end

  defp package_surface_entries do
    [
      Types.new_package_surface_entry(
        surface: "`crosswake` primary package",
        package_class: :core,
        why:
          "Route-policy DSL, manifest contract, compatibility axes, bounded-bridge vocabulary, shell generators, doctor, support matrix, release rules, and proof posture stay in one obvious Phoenix-first package.",
        release_burden:
          "Hex package SemVer moves independently, while support truth still follows manifest_schema_version, bridge_protocol_version, and native_runtime_version.",
        guide: "guides/install.md#package-surface"
      ),
      Types.new_package_surface_entry(
        surface: "Phoenix-facing commerce seam vocabulary",
        package_class: :core,
        why:
          "`paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, and `reconciliation_evidence` stay normalized and backend-truthful in core without embedding storefront providers.",
        release_burden:
          "Semantics may evolve in core, but provider adapters and native storefront logic remain outside the base package.",
        guide: "guides/capabilities.md#packaging-ledger"
      ),
      Types.new_package_surface_entry(
        surface: "Provider adapters and native-heavy integrations",
        package_class: :companion,
        why:
          "Storefront adapters, media/upload/capture, rollout, auth/session, notifications, and audit/operator seams carry native binary churn or backend coupling beyond core.",
        release_burden:
          "First-party companions declare minimum compatible ranges against core, compatibility axes, and capability-family majors.",
        guide: "guides/compatibility.md#companion-compatibility-contract"
      ),
      Types.new_package_surface_entry(
        surface: "Checked-in example hosts and install walkthroughs",
        package_class: :example_docs_only,
        why:
          "Examples, walkthroughs, reviewer playbooks, and vendor recipes teach boundaries and proof posture without becoming separate runtime packages.",
        release_burden:
          "Not first-class supported as package surfaces; promotion requires reclassification plus proof and support-matrix updates.",
        guide: "guides/capabilities.md#docs-only-boundary"
      ),
      Types.new_package_surface_entry(
        surface: "Standalone public shell packages",
        package_class: :defer,
        why:
          "Separately versioned shell artifacts stay deferred until release choreography and compatibility policy are mature enough to support them honestly.",
        release_burden:
          "No first-class package commitment yet; any future promotion must land with runtime-line rules and rebuild guidance.",
        guide: "guides/compatibility.md#runtime-line-rules"
      )
    ]
  end

  defp release_boundary_entries do
    [
      Types.new_release_boundary_entry(
        target: "core",
        versioning: "Independent SemVer for the `crosswake` Hex package.",
        compatibility_contract:
          "package versions alone do not define support truth; manifest_schema_version, bridge_protocol_version, and native_runtime_version stay canonical.",
        release_rule:
          "Manifest-major, bridge-major, and runtime-line changes must update support docs and doctor before release."
      ),
      Types.new_release_boundary_entry(
        target: "companion",
        versioning: "Independent SemVer per first-party companion.",
        compatibility_contract:
          "Each companion declares minimum compatible ranges for core, all three compatibility axes, and exposed capability-family majors.",
        release_rule:
          "Companion support cannot expand until the adapter publishes explicit compatibility ranges and fail-closed guidance."
      ),
      Types.new_release_boundary_entry(
        target: "ios_shell",
        versioning:
          "Platform artifact build numbers may differ, but the shell publishes against the shared native runtime line.",
        compatibility_contract:
          "Breaking bridge semantics require a bridge_protocol_version major bump plus a compatible shell artifact before support widens.",
        release_rule:
          "Changes touching native code, entitlements, permissions, registration, or packaged runtime behavior move the native_runtime_version line and mark rebuild required."
      ),
      Types.new_release_boundary_entry(
        target: "android_shell",
        versioning:
          "Platform artifact build numbers may differ, but the shell publishes against the shared native runtime line.",
        compatibility_contract:
          "Breaking bridge semantics require a bridge_protocol_version major bump plus a compatible shell artifact before support widens.",
        release_rule:
          "Changes touching native code, entitlements, permissions, registration, or packaged runtime behavior move the native_runtime_version line and mark rebuild required."
      )
    ]
  end

  defp change_class_entries do
    [
      Types.new_change_class_entry(
        change_class: "docs-only",
        what_changed:
          "Guides, wording, examples, support notes, or advisory docs changed without changing manifest semantics, compatibility-axis values, capability versions, shell templates, companion code, or proof expectations.",
        adopter_action: "Read the updated guidance and rerun docs integrity only.",
        compatibility_signal: "No compatibility-axis or capability-version change.",
        required_proof: "docs integrity only"
      ),
      Types.new_change_class_entry(
        change_class: "core-only/no native rebuild",
        what_changed:
          "Core Elixir behavior, docs generation, doctor, support rendering, or validation changed inside the already-supported schema, bridge, runtime, and capability versions.",
        adopter_action:
          "Update the Hex package and rerun core contract + doctor/support proof without rebuilding native shells.",
        compatibility_signal:
          "Existing manifest_schema_version, bridge_protocol_version, native_runtime_version, and capability majors stay in line.",
        required_proof: "core contract + doctor/support proof"
      ),
      Types.new_change_class_entry(
        change_class: "compatibility-bump only",
        what_changed:
          "Compatibility declarations or package windows narrowed so some older combinations now fail closed, but a fresh binary is not automatically required for already-compatible adopters.",
        adopter_action:
          "Check the compatibility window, confirm your shipped shell/runtime is still in range, and run fail-closed compatibility fixtures.",
        compatibility_signal:
          "manifest_schema_version, bridge_protocol_version, native_runtime_version, or capability required-version declarations changed support windows.",
        required_proof: "fail-closed compatibility fixtures"
      ),
      Types.new_change_class_entry(
        change_class: "native or companion rebuild required",
        what_changed:
          "Native code, generated shell projects, entitlements, permissions, platform config, native dependencies, or companion-native integration code changed.",
        adopter_action:
          "Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes.",
        compatibility_signal:
          "Every rebuild-required change carries explicit compatibility declarations, especially native_runtime_version, bridge_protocol_version, manifest_schema_version, and capability required-version shifts.",
        required_proof: "core proof plus generated-shell or companion verification lanes"
      )
    ]
  end

  defp capability_family_entries(capability_registry) do
    capability_registry
    |> Enum.map(fn {_id, capability} -> capability end)
    |> Enum.filter(fn capability -> capability.id == capability.family end)
    |> Enum.map(fn %Capability{} = capability ->
      Types.new_capability_support_entry(
        family: capability.family,
        owner: capability.owner,
        posture: capability_posture(capability),
        baseline_status: :supported,
        proof_status: capability_proof_status(capability),
        package_class: capability.package_class,
        proof_class: capability.proof_class,
        rebuild: capability.rebuild,
        prerequisites: capability_prerequisites(capability),
        denial: capability.denial,
        fallback: capability_fallback(capability),
        guide: capability.guide,
        verification_method: capability_verification_method(capability)
      )
    end)
  end

  defp validate_capability_families_present(errors, %SupportMatrix{} = support_matrix) do
    if support_matrix.capability_families == [] do
      [
        %{
          key: :capability_families,
          message: "support matrix is missing manifest-derived capability family entries",
          hint: "derive capability family support rows from manifest capability registry metadata"
        }
        | errors
      ]
    else
      errors
    end
  end

  defp validate_phase51_support_truth(errors) do
    errors
    |> validate_action_class_rows()
    |> validate_promotion_rule_rows()
  end

  defp validate_action_class_rows(errors) do
    allowed =
      ~w(docs_only route_manifest compatibility native_shell companion_native provider_adapter)

    action_classes()
    |> Enum.reduce(errors, fn entry, acc ->
      cond do
        entry.action_class not in allowed ->
          [
            %{
              key: :action_classes,
              message: "unknown action_class #{inspect(entry.action_class)}",
              hint: "use one of #{Enum.join(allowed, ", ")}"
            }
            | acc
          ]

        !is_boolean(entry.rebuild_required) or entry.guide_anchor in [nil, ""] ->
          [
            %{
              key: :action_classes,
              message: "action_class #{entry.action_class} is missing rebuild or guide metadata",
              hint: "every action class must include rebuild_required and guide_anchor"
            }
            | acc
          ]

        true ->
          acc
      end
    end)
  end

  defp validate_promotion_rule_rows(errors) do
    action_classes = action_classes() |> MapSet.new(& &1.action_class)

    promotion_rules()
    |> Enum.reduce(errors, fn entry, acc ->
      cond do
        entry.action_class not in action_classes ->
          [
            %{
              key: :promotion_rules,
              message:
                "promotion rule #{entry.claim_id} references unknown action_class #{inspect(entry.action_class)}",
              hint: "promotion rules must reference a canonical action class"
            }
            | acc
          ]

        entry.required_evidence == [] or entry.required_docs_anchors == [] or
            entry.check_ids == [] ->
          [
            %{
              key: :promotion_rules,
              message: "promotion rule #{entry.claim_id} is missing evidence, docs, or check ids",
              hint: "criteria-as-code promotion rules must be auditable before support can widen"
            }
            | acc
          ]

        entry.demotion_trigger in [nil, ""] ->
          [
            %{
              key: :promotion_rules,
              message: "promotion rule #{entry.claim_id} is missing a demotion trigger",
              hint: "promotion and demotion must both be explicit"
            }
            | acc
          ]

        true ->
          acc
      end
    end)
  end

  # D-10a: A CapabilitySupportEntry with proof_class :advisory has a CI-only evidence
  # corpus. Claiming :device_verified on a CI-only entry is evidence laundering.
  # iOS native-screen entries (proof_class: :merge_blocking) are allowed :device_verified.
  # Constructor default :none is always safe and never rejected.
  defp validate_verification_method_invariant(errors, %SupportMatrix{} = support_matrix) do
    support_matrix.capability_families
    |> Enum.reduce(errors, fn entry, acc ->
      cond do
        entry.verification_method == :device_verified and entry.proof_class == :advisory ->
          [
            %{
              key: :capability_families,
              message:
                "capability family #{inspect(entry.family)} claims :device_verified but has proof_class :advisory (CI-only corpus) — evidence laundering (D-10a)",
              hint:
                ":device_verified requires real-device proof evidence; CI-only entries must use :jvm_hermetic, :emulator_advisory, or :none"
            }
            | acc
          ]

        true ->
          acc
      end
    end)
  end

  # D-10a (rebuild_matrix surface): The rebuild_matrix rows must not claim :device_verified
  # for any runtime-line band without backing real-device promotion evidence. In Phase 64,
  # the shell.android.device_verified promotion rule is explicitly GATED (Phases 67/68) and
  # there is no passed device-verified promotion evidence, so :device_verified is unconditionally
  # rejected on all rebuild_matrix rows. CI-only bands must use :jvm_hermetic. This structural
  # gate makes evidence laundering via the rebuild_matrix surface impossible to re-introduce
  # without being caught by validate/1.
  defp validate_rebuild_matrix_evidence(errors, %SupportMatrix{} = support_matrix) do
    support_matrix.rebuild_matrix
    |> Enum.reduce(errors, fn row, acc ->
      cond do
        row.evidence_tier == :device_verified ->
          [
            %{
              key: :rebuild_matrix,
              message:
                "rebuild_matrix row for runtime_line #{inspect(row.runtime_line)} claims evidence_tier :device_verified — evidence laundering (D-10a); no device-verified promotion evidence exists in Phase 64",
              hint:
                ":device_verified on a rebuild_matrix row requires real-device proof gated until Phases 67/68; CI-only bands must use :jvm_hermetic"
            }
            | acc
          ]

        true ->
          acc
      end
    end)
  end

  defp action_class_entries do
    [
      Types.new_action_class_entry(
        action_class: "docs_only",
        subject: "Public guides, examples, and support notes",
        required_action: "Read updated guidance and rerun docs integrity checks.",
        rebuild_required: false,
        reason:
          "Docs-only changes do not change manifest semantics, compatibility axes, native code, or proof expectations.",
        guide_anchor: "guides/support_matrix.md#action-classes"
      ),
      Types.new_action_class_entry(
        action_class: "route_manifest",
        subject: "Phoenix route policy and manifest metadata",
        required_action:
          "Update the Hex package, regenerate manifest truth, and run core contract plus doctor/support proof.",
        rebuild_required: false,
        reason:
          "Route and manifest metadata can stay core-only when schema, bridge, runtime, and capability major versions remain compatible.",
        guide_anchor: "guides/support_matrix.md#action-classes"
      ),
      Types.new_action_class_entry(
        action_class: "compatibility",
        subject: "Compatibility windows and required version declarations",
        required_action:
          "Check compatibility windows and run fail-closed compatibility fixtures before release.",
        rebuild_required: false,
        reason:
          "A narrowed support window may reject older combinations without requiring already-compatible adopters to rebuild.",
        guide_anchor: "guides/compatibility.md#runtime-line-rules"
      ),
      Types.new_action_class_entry(
        action_class: "native_shell",
        subject: "iOS or Android shell artifacts and native runtime line",
        required_action:
          "Rebuild affected shells, publish the updated runtime line, and rerun generated-shell verification lanes.",
        rebuild_required: true,
        reason:
          "Native code, entitlements, permissions, platform config, and generated shell projects require host shell rebuild verification.",
        guide_anchor: "guides/native_shell.md#boundary-warnings--rough-edges"
      ),
      Types.new_action_class_entry(
        action_class: "companion_native",
        subject: "First-party companion bindings or companion-native surfaces",
        required_action:
          "Verify companion dependency health, compatibility ranges, and fail-closed fallback posture before widening support.",
        rebuild_required: true,
        reason:
          "Companion-native integrations can carry native binary churn or backend coupling beyond core route metadata.",
        guide_anchor: "guides/companions.md#support-truth-and-proof-posture"
      ),
      Types.new_action_class_entry(
        action_class: "provider_adapter",
        subject: "Storefront/provider SDK adapters",
        required_action:
          "Keep provider proof advisory until adapter implementation, provider setup, backend reconciliation, docs, and promotion criteria all pass.",
        rebuild_required: true,
        reason:
          "Provider SDK adapters require native/provider setup and cannot be treated as shipped support from seam-only contracts.",
        guide_anchor: "guides/commerce.md#provider-adapter-defers"
      )
    ]
  end

  defp promotion_rule_entries do
    [
      promotion_rule(
        claim_id: "shell.ios.generated_project",
        claim_scope: "Generated iOS shell support",
        current_proof_class: :merge_blocking,
        promotes_to: :supported,
        evidence_class: "generated_shell",
        required_evidence: ["script/verify_generated_ios_shell.sh", "support matrix parity"],
        minimum_consecutive_passes: 1,
        freshness_window: "current release branch",
        failure_budget: "zero merge-blocking failures",
        required_platforms: ["ios"],
        required_docs_anchors: ["guides/support_matrix.md", "guides/native_shell.md"],
        change_class: "native or companion rebuild required",
        action_class: "native_shell",
        check_ids: ["diag.shell.verification_required"],
        demotion_trigger:
          "Demote to verification_required when generated-shell proof fails or native_runtime_version support narrows."
      ),
      promotion_rule(
        claim_id: "shell.android.generated_project",
        claim_scope: "Generated Android shell support",
        current_proof_class: :advisory,
        promotes_to: :merge_blocking,
        evidence_class: "generated_shell",
        required_evidence: [
          "script/verify_generated_android_shell.sh",
          "Java-enabled BridgeChannel proof"
        ],
        minimum_consecutive_passes: 2,
        freshness_window: "current release branch",
        failure_budget: "zero merge-blocking failures",
        required_platforms: ["android"],
        required_docs_anchors: ["guides/support_matrix.md", "guides/native_shell.md"],
        change_class: "native or companion rebuild required",
        action_class: "native_shell",
        check_ids: ["diag.shell.verification_required"],
        demotion_trigger:
          "Keep or demote to verification_required when Android JVM or generated-shell proof is stale or unavailable."
      ),
      promotion_rule(
        claim_id: "notification_token.provider_snapshot",
        claim_scope: "Notification token provider snapshot readiness",
        current_proof_class: :advisory,
        promotes_to: :merge_blocking,
        evidence_class: "provider_snapshot",
        required_evidence: [
          "notification_token capability contract",
          "provider-tagged snapshot fixtures"
        ],
        minimum_consecutive_passes: 2,
        freshness_window: "current release branch",
        failure_budget: "zero contract failures",
        required_platforms: ["ios", "android"],
        required_docs_anchors: ["guides/support_matrix.md", "guides/capabilities.md"],
        change_class: "native or companion rebuild required",
        action_class: "companion_native",
        check_ids: ["diag.notification.token_provider_snapshot_only"],
        demotion_trigger:
          "Demote when provider snapshot proof is stale, missing, or confused with Chimeway delivery support."
      ),
      promotion_rule(
        claim_id: "auth.sigra.session_authority",
        claim_scope:
          "Sigra session-authority route evaluator, handoff contract, step-up ceremony, auth-return boundary, telemetry, and security closeout support",
        current_proof_class: :merge_blocking,
        promotes_to: :merge_blocking,
        evidence_class: "session_authority_handoff_step_up_auth_return_contract",
        required_evidence: [
          "auth posture route fixtures",
          "session authority evaluator proof",
          "step_up_required denial-code proof",
          "single-use handoff ticket lifecycle proof",
          "server-record redemption and audit proof",
          "server-owned step-up intent lifecycle proof",
          "shared Plug/LiveView ceremony proof",
          "OAuth/passkey/native auth-return envelope proof",
          "host-owned auth-return attempt replay proof",
          "verified-link-first native return proof",
          "low-cardinality auth telemetry proof",
          "security closeout proof"
        ],
        minimum_consecutive_passes: 1,
        freshness_window: "current release branch",
        failure_budget: "zero contract failures",
        required_platforms: ["ios", "android"],
        required_docs_anchors: ["guides/support_matrix.md", "guides/companions.md"],
        change_class: "native or companion rebuild required",
        action_class: "companion_native",
        check_ids: ["diag.auth.sigra_session_authority"],
        demotion_trigger:
          "Demote if route predicates, auth_posture, auth_return route policy, step_up_required/auth.handoff/auth.step_up_intent/auth.return denial codes, auth telemetry metadata, handoff/step-up/auth-return server-record proof, security closeout, or Sigra docs drift from support truth."
      ),
      promotion_rule(
        claim_id: "purchase_intent.provider.storekit",
        claim_scope: "StoreKit purchase-intent provider adapter",
        current_proof_class: :advisory,
        promotes_to: :merge_blocking,
        evidence_class: "provider_adapter",
        required_evidence: [
          "deterministic adapter contract proof",
          "backend reconciliation authority proof",
          "docs-contract parity proof",
          "advisory storefront/provider lane evidence"
        ],
        minimum_consecutive_passes: 3,
        freshness_window: "current adapter release",
        failure_budget: "zero entitlement-authority failures",
        required_platforms: ["ios"],
        required_docs_anchors: ["guides/support_matrix.md", "guides/commerce.md"],
        change_class: "native or companion rebuild required",
        action_class: "provider_adapter",
        check_ids: [
          "diag.provider.storekit.advisory_proof",
          "diag.provider.adapter_shipped_seams"
        ],
        demotion_trigger:
          "Remain advisory until StoreKit adapter, provider setup, docs parity, and backend reconciliation proof all pass."
      ),
      promotion_rule(
        claim_id: "restore_intent.provider.storekit",
        claim_scope: "StoreKit restore-intent provider adapter",
        current_proof_class: :advisory,
        promotes_to: :merge_blocking,
        evidence_class: "provider_adapter",
        required_evidence: [
          "deterministic adapter contract proof",
          "backend reconciliation authority proof",
          "docs-contract parity proof",
          "advisory storefront/provider lane evidence"
        ],
        minimum_consecutive_passes: 3,
        freshness_window: "current adapter release",
        failure_budget: "zero entitlement-authority failures",
        required_platforms: ["ios"],
        required_docs_anchors: ["guides/support_matrix.md", "guides/commerce.md"],
        change_class: "native or companion rebuild required",
        action_class: "provider_adapter",
        check_ids: [
          "diag.provider.storekit.advisory_proof",
          "diag.provider.adapter_shipped_seams"
        ],
        demotion_trigger:
          "Remain advisory until StoreKit restore evidence stays backend-owned and proof/docs parity pass."
      ),
      promotion_rule(
        claim_id: "purchase_intent.provider.play_billing",
        claim_scope: "Play Billing purchase-intent provider adapter",
        current_proof_class: :advisory,
        promotes_to: :merge_blocking,
        evidence_class: "provider_adapter",
        required_evidence: [
          "deterministic adapter contract proof",
          "backend reconciliation authority proof",
          "docs-contract parity proof",
          "advisory storefront/provider lane evidence"
        ],
        minimum_consecutive_passes: 3,
        freshness_window: "current adapter release",
        failure_budget: "zero entitlement-authority failures",
        required_platforms: ["android"],
        required_docs_anchors: ["guides/support_matrix.md", "guides/commerce.md"],
        change_class: "native or companion rebuild required",
        action_class: "provider_adapter",
        check_ids: [
          "diag.provider.play_billing.advisory_proof",
          "diag.provider.adapter_shipped_seams"
        ],
        demotion_trigger:
          "Remain advisory until Play Billing adapter, provider setup, docs parity, and backend reconciliation proof all pass."
      ),
      promotion_rule(
        claim_id: "restore_intent.provider.play_billing",
        claim_scope: "Play Billing restore-intent provider adapter",
        current_proof_class: :advisory,
        promotes_to: :merge_blocking,
        evidence_class: "provider_adapter",
        required_evidence: [
          "deterministic adapter contract proof",
          "backend reconciliation authority proof",
          "docs-contract parity proof",
          "advisory storefront/provider lane evidence"
        ],
        minimum_consecutive_passes: 3,
        freshness_window: "current adapter release",
        failure_budget: "zero entitlement-authority failures",
        required_platforms: ["android"],
        required_docs_anchors: ["guides/support_matrix.md", "guides/commerce.md"],
        change_class: "native or companion rebuild required",
        action_class: "provider_adapter",
        check_ids: [
          "diag.provider.play_billing.advisory_proof",
          "diag.provider.adapter_shipped_seams"
        ],
        demotion_trigger:
          "Remain advisory until Play Billing restore evidence stays backend-owned and proof/docs parity pass."
      ),
      # D-18: Android JVM hermetic promotion criteria — CI-level evidence only.
      # required_verification_method: :jvm_hermetic gates this promotion.
      # jvm_hermetic promotion MUST NOT be read as device_verified (D-19).
      promotion_rule(
        claim_id: "shell.android.jvm_hermetic",
        claim_scope: "Android shell JVM hermetic CI proof promotion",
        current_proof_class: :advisory,
        promotes_to: :merge_blocking,
        evidence_class: "jvm_hermetic_ci",
        required_evidence: [
          "script/verify_generated_android_shell.sh",
          "Java-enabled JVM BridgeChannel hermetic proof",
          "support-matrix rebuild_matrix parity",
          "docs-contract parity for Android runtime-line"
        ],
        minimum_consecutive_passes: 3,
        freshness_window: "current release branch, within 30 CI runs",
        failure_budget: "zero consecutive failures; single failure resets counter",
        required_platforms: ["android"],
        required_docs_anchors: [
          "guides/support_matrix.md",
          "guides/native_shell.md#android-verification"
        ],
        change_class: "native or companion rebuild required",
        action_class: "native_shell",
        check_ids: [
          "diag.shell.android.jvm_hermetic",
          "diag.shell.verification_required"
        ],
        demotion_trigger:
          "Demote to verification_required when Android JVM hermetic CI proof is stale, fails, or coverage drops below the freshness window. jvm_hermetic promotion MUST NOT be read as device_verified — CI-level evidence is not device/emulator evidence.",
        required_verification_method: :jvm_hermetic
      ),
      # D-19: Android device-verified promotion criteria — GATED until Phases 67/68.
      # Device/emulator proof is unavailable until Phase 67 (Android shell implementation)
      # and Phase 68 (Android verification closure and device-UAT).
      # jvm_hermetic promotion MUST NOT be read as device_verified.
      promotion_rule(
        claim_id: "shell.android.device_verified",
        claim_scope: "Android shell device/emulator-verified proof promotion — GATED until Phases 67/68",
        current_proof_class: :advisory,
        promotes_to: :merge_blocking,
        evidence_class: "device_verified",
        required_evidence: [
          "Android emulator advisory lane evidence (Phase 68)",
          "device-UAT checklist completion (Phase 68)",
          "capability-parity-locked device proof",
          "docs-contract parity for Android device-verified runtime-line"
        ],
        minimum_consecutive_passes: 3,
        freshness_window: "current release branch, within 10 device-UAT runs",
        failure_budget: "zero consecutive failures; single failure resets counter",
        required_platforms: ["android"],
        required_docs_anchors: [
          "guides/support_matrix.md",
          "guides/native_shell.md#android-device-uat"
        ],
        change_class: "native or companion rebuild required",
        action_class: "native_shell",
        check_ids: [
          "diag.shell.android.device_verified",
          "diag.shell.verification_required"
        ],
        demotion_trigger:
          "Device/emulator proof is unavailable until Phase 67 (Android shell implementation) and Phase 68 (Android verification closure and device-UAT checklist). jvm_hermetic promotion MUST NOT be read as device_verified — CI-level JVM hermetic evidence does not constitute real-device or emulator proof. Demote to verification_required if device-UAT evidence is stale or if the device lane drops below the freshness window.",
        required_verification_method: :device_verified
      )
    ]
  end

  defp promotion_rule(attrs), do: Types.new_promotion_rule_entry(attrs)

  defp support_entry(target, version, status, opts) do
    Types.new_support_entry(
      target: target,
      version: version,
      status: status,
      baseline_status: Keyword.get(opts, :baseline_status, status),
      proof_status: Keyword.get(opts, :proof_status, status),
      proof: Keyword.get(opts, :proof),
      notes: Keyword.get(opts, :notes),
      boundary_link: Keyword.get(opts, :boundary_link)
    )
  end

  # iOS-backed native-screen capabilities with merge_blocking proof require real-device proof.
  # Deferred native_screen entries (proof_class: :advisory, package_class: :defer) are NOT
  # device-verified — they are advisory/deferred and must not claim device evidence (D-10a).
  # notification_token uses the Android JVM hermetic CI lane (advisory proof class).
  # All other capabilities default to :none — no platform-specific evidence tier claimed.
  defp capability_verification_method(%Capability{
         owner: :native_screen,
         proof_class: :merge_blocking
       }),
       do: :device_verified

  defp capability_verification_method(%Capability{id: "notification_token"}), do: :jvm_hermetic

  defp capability_verification_method(%Capability{}), do: :none

  defp capability_posture(%Capability{id: "deep_link"}), do: "activation_first"
  defp capability_posture(%Capability{id: "file_picker"}), do: "transfer_backed"
  defp capability_posture(%Capability{id: "notification_token"}), do: "provider_snapshot"
  defp capability_posture(%Capability{id: "permissions.status"}), do: "alias_snapshot"
  defp capability_posture(%Capability{owner: :native_screen}), do: "native_screen"
  defp capability_posture(%Capability{owner: :backend_seam}), do: "backend_seam"
  defp capability_posture(%Capability{}), do: "bounded_bridge"

  defp capability_prerequisites(%Capability{
         id: "entitlement_snapshot",
         prerequisites: prerequisites
       }) do
    prerequisites ++ ["freshness posture (fresh/stale/unknown) surfaced before access checks"]
  end

  defp capability_prerequisites(%Capability{
         id: "reconciliation_evidence",
         prerequisites: prerequisites
       }) do
    prerequisites ++ ["pending and awaiting_verification reconciliation states stay non-granting"]
  end

  defp capability_prerequisites(%Capability{prerequisites: prerequisites}), do: prerequisites

  defp capability_fallback(%Capability{id: "entitlement_snapshot"}) do
    "Fail closed for access decisions when snapshot freshness is stale or unknown until refreshed backend authority is available; pending and awaiting_verification states never grant entitlement."
  end

  defp capability_fallback(%Capability{id: "reconciliation_evidence"}) do
    "Treat device/storefront/webhook/support evidence as non-authoritative reconciliation input; pending_purchase, pending_restore, and awaiting_verification remain non-granting until backend projection refreshes authority."
  end

  defp capability_fallback(%Capability{fallback: fallback}), do: fallback

  defp capability_proof_status(%Capability{id: "notification_token"}), do: :verification_required
  defp capability_proof_status(%Capability{id: "deep_link"}), do: :supported

  defp capability_proof_status(%Capability{proof_class: :merge_blocking}),
    do: :verification_required

  defp capability_proof_status(%Capability{proof_class: :advisory}), do: :supported

  # D-08 locked display-string mapping for runtime gate state.
  # Kill-switch clause MUST come first for precedence — an active kill switch overrides
  # gate_status regardless of its value (RESEARCH critical pitfall).
  defp gate_state_display(%Crosswake.Companion.State{kill_switch_status: :active}), do: "killed"
  defp gate_state_display(%Crosswake.Companion.State{gate_status: :active}), do: "gated"

  defp gate_state_display(%Crosswake.Companion.State{gate_status: {:rolling_out, n}}),
    do: "rolling_out (#{n}%)"

  defp gate_state_display(%Crosswake.Companion.State{gate_status: :inactive}), do: nil
  defp gate_state_display(%Crosswake.Companion.State{gate_status: :unconfigured}), do: nil

  defp gate_state_display(%Crosswake.Companion.State{} = state) do
    "unknown(gate_status=#{inspect(state.gate_status)},kill_switch=#{inspect(state.kill_switch_status)})"
  end
end
