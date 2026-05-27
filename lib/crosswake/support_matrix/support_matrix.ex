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
  alias Crosswake.Manifest.Types.SupportEntry
  alias Crosswake.Manifest.Types.SupportMatrix

  @statuses [:supported, :verification_required, :unsupported]
  @commerce_corridor_entries [
    %{
      corridor_role: "paywall_entry",
      owner_posture: "phoenix_owned",
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
      native_rebuild_required: false
    },
    %{
      corridor_role: "account_management",
      owner_posture: "phoenix_owned",
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
      native_rebuild_required: false
    },
    %{
      corridor_role: "purchase_intent",
      owner_posture: "native_or_companion_required",
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
      native_rebuild_required: true
    },
    %{
      corridor_role: "restore_intent",
      owner_posture: "native_or_companion_required",
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
      native_rebuild_required: true
    }
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
          notes: "Generated iOS shell artifacts are supported while the Phase 5 iOS verification hook stays green.",
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
      change_classes: change_class_entries()
    )
  end

  @spec validate(SupportMatrix.t()) :: [map()]
  def validate(%SupportMatrix{} = support_matrix) do
    []
    |> validate_categories_present(support_matrix)
    |> validate_exact_statuses(support_matrix)
    |> validate_narrow_baseline(support_matrix)
    |> validate_capability_families_present(support_matrix)
  end

  @spec statuses() :: [atom()]
  def statuses, do: @statuses

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
  def capability_families(%SupportMatrix{} = support_matrix), do: support_matrix.capability_families

  @spec package_surfaces(SupportMatrix.t()) :: [PackageSurfaceEntry.t()]
  def package_surfaces(%SupportMatrix{} = support_matrix), do: support_matrix.package_surfaces

  @spec release_boundaries(SupportMatrix.t()) :: [ReleaseBoundaryEntry.t()]
  def release_boundaries(%SupportMatrix{} = support_matrix), do: support_matrix.release_boundaries

  @spec change_classes(SupportMatrix.t()) :: [ChangeClassEntry.t()]
  def change_classes(%SupportMatrix{} = support_matrix), do: support_matrix.change_classes

  @spec commerce_corridors() :: [map()]
  def commerce_corridors, do: @commerce_corridor_entries

  @spec commerce_corridor_denial_codes() :: [String.t()]
  def commerce_corridor_denial_codes do
    @commerce_corridor_entries
    |> Enum.flat_map(& &1.denial_codes)
    |> Enum.uniq()
    |> Enum.sort()
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
        versioning: "Platform artifact build numbers may differ, but the shell publishes against the shared native runtime line.",
        compatibility_contract:
          "Breaking bridge semantics require a bridge_protocol_version major bump plus a compatible shell artifact before support widens.",
        release_rule:
          "Changes touching native code, entitlements, permissions, registration, or packaged runtime behavior move the native_runtime_version line and mark rebuild required."
      ),
      Types.new_release_boundary_entry(
        target: "android_shell",
        versioning: "Platform artifact build numbers may differ, but the shell publishes against the shared native runtime line.",
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
        required_proof:
          "core proof plus generated-shell or companion verification lanes"
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
        guide: capability.guide
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

  defp capability_posture(%Capability{id: "deep_link"}), do: "activation_first"
  defp capability_posture(%Capability{id: "file_picker"}), do: "transfer_backed"
  defp capability_posture(%Capability{id: "notification_token"}), do: "provider_snapshot"
  defp capability_posture(%Capability{id: "permissions.status"}), do: "alias_snapshot"
  defp capability_posture(%Capability{owner: :native_screen}), do: "native_screen"
  defp capability_posture(%Capability{owner: :backend_seam}), do: "backend_seam"
  defp capability_posture(%Capability{}), do: "bounded_bridge"

  defp capability_prerequisites(%Capability{id: "entitlement_snapshot", prerequisites: prerequisites}) do
    prerequisites ++ ["freshness posture (fresh/stale/unknown) surfaced before access checks"]
  end

  defp capability_prerequisites(%Capability{id: "reconciliation_evidence", prerequisites: prerequisites}) do
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
  defp capability_proof_status(%Capability{proof_class: :merge_blocking}), do: :verification_required
  defp capability_proof_status(%Capability{proof_class: :advisory}), do: :supported
end
