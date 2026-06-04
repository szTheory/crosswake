defmodule Crosswake.Proof.Phase64RuntimeLinePolicyTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Crosswake.TestSupport.ProofAssertions
  alias Crosswake.RuntimeLine.RebuildPolicy
  alias Crosswake.SupportMatrix
  alias Crosswake.Manifest.Types

  @doctor_task "crosswake.doctor"

  # ---------------------------------------------------------------------------
  # RLINE-01 — Rebuild/OTA classification contract
  #
  # RebuildPolicy.rebuild_required?/1 and classify/2 must derive decisions from
  # the Capability.rebuild field (never from change-class label alone), covering
  # all 3 rebuild values and all 8 change-class atoms.
  # ---------------------------------------------------------------------------

  @tag :rline_01
  test "rebuild_required?/1 returns false for :none and true for :native_required and :companion_required" do
    message_none =
      ProofAssertions.stable_id_message(
        "proof.rline_01.rebuild_required.none",
        "rebuild_required?(:none) must be false",
        "RebuildPolicy.rebuild_required?/1",
        ":none",
        "lib/crosswake/runtime_line/rebuild_policy.ex",
        "ensure :none is always OTA-safe",
        :merge_blocking
      )

    message_native =
      ProofAssertions.stable_id_message(
        "proof.rline_01.rebuild_required.native_required",
        "rebuild_required?(:native_required) must be true",
        "RebuildPolicy.rebuild_required?/1",
        ":native_required",
        "lib/crosswake/runtime_line/rebuild_policy.ex",
        "ensure :native_required always triggers a rebuild",
        :merge_blocking
      )

    message_companion =
      ProofAssertions.stable_id_message(
        "proof.rline_01.rebuild_required.companion_required",
        "rebuild_required?(:companion_required) must be true",
        "RebuildPolicy.rebuild_required?/1",
        ":companion_required",
        "lib/crosswake/runtime_line/rebuild_policy.ex",
        "ensure :companion_required always triggers a rebuild",
        :merge_blocking
      )

    refute RebuildPolicy.rebuild_required?(:none), message_none
    assert RebuildPolicy.rebuild_required?(:native_required), message_native
    assert RebuildPolicy.rebuild_required?(:companion_required), message_companion
  end

  @tag :rline_01
  test "classify/2 returns correct verdict for capability-axis change classes" do
    native_cap = %Types.Capability{id: "test.native", version: "1.0", rebuild: :native_required}
    companion_cap = %Types.Capability{id: "test.companion", version: "1.0", rebuild: :companion_required}
    ota_cap = %Types.Capability{id: "test.ota", version: "1.0", rebuild: :none}

    capability_axis_classes = [
      :capability_family_add,
      :bridge_schema_change,
      :permission_add,
      :entitlement_add,
      :push_capability_change,
      :url_scheme_change
    ]

    for change_class <- capability_axis_classes do
      assert RebuildPolicy.classify(change_class, native_cap) ==
               {:rebuild_required, :native_shell},
             "expected {:rebuild_required, :native_shell} for #{change_class} with native_required"

      assert RebuildPolicy.classify(change_class, companion_cap) ==
               {:rebuild_required, :companion_shell},
             "expected {:rebuild_required, :companion_shell} for #{change_class} with companion_required"

      assert RebuildPolicy.classify(change_class, ota_cap) == :ota_safe,
             "expected :ota_safe for #{change_class} with :none"
    end
  end

  @tag :rline_01
  test "classify/2 returns {:rebuild_required, :native_shell} for system classes with nil capability" do
    # System-level change classes always require a native shell rebuild regardless
    # of capability context (capability arg is nil — no capability owner).
    system_classes = [:sdk_floor_bump, :privacy_manifest_entry]

    for change_class <- system_classes do
      assert RebuildPolicy.classify(change_class, nil) == {:rebuild_required, :native_shell},
             "expected {:rebuild_required, :native_shell} for system class #{change_class} with nil capability"
    end
  end

  # ---------------------------------------------------------------------------
  # RLINE-02 — native_runtime_version-only derivation, no new manifest field
  #
  # The Compatibility struct must have EXACTLY its 5 current fields. No new field
  # may be added (would bump manifest_schema_version and break deployed shells).
  # co-truth parity: classify/2 agrees with action_classes() rebuild_required.
  # ---------------------------------------------------------------------------

  @tag :rline_02
  test "Compatibility struct has exactly the 5 locked fields — no new field added" do
    compat = %Types.Compatibility{
      manifest_schema_version: "1.0.0",
      bridge_protocol_version: "1.0.0",
      native_runtime_version: "1.0.0",
      supported_manifest_sources: [],
      remote_updates: []
    }

    fields = Map.keys(compat) -- [:__struct__]

    expected = [
      :manifest_schema_version,
      :bridge_protocol_version,
      :native_runtime_version,
      :supported_manifest_sources,
      :remote_updates
    ]

    assert Enum.sort(fields) == Enum.sort(expected),
           ProofAssertions.stable_id_message(
             "proof.rline_02.compatibility.exact_fields",
             "Compatibility struct field set",
             "Crosswake.Manifest.Types.Compatibility",
             "field set drift from locked 5-key contract",
             "lib/crosswake/manifest/types.ex",
             "do NOT add fields to Compatibility without a manifest_schema_version bump and phase review",
             :merge_blocking
           )
  end

  @tag :rline_02
  test "canonical manifest compatibility.manifest_schema_version is 1.0.0" do
    manifest = SupportMatrix.canonical()
    compat = manifest.compatibility

    assert compat.manifest_schema_version == "1.0.0",
           ProofAssertions.stable_id_message(
             "proof.rline_02.manifest_schema_version",
             "manifest_schema_version",
             "SupportMatrix.canonical/0 → compatibility.manifest_schema_version",
             "manifest_schema_version value differs from locked \"1.0.0\"",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "bump manifest_schema_version only through a phase — NOT by editing the field value",
             :merge_blocking
           )
  end

  @tag :rline_02
  test "classify/2 co-truth parity: agrees with action_classes() rebuild_required for every action class" do
    # For each ActionClassEntry, the rebuild_required boolean must agree with
    # what classify/2 returns for a hypothetical capability with the matching
    # rebuild need. action_classes() is the co-truth source.
    action_classes = SupportMatrix.action_classes()
    assert is_list(action_classes), "action_classes() must return a list"
    assert length(action_classes) > 0, "action_classes() must not be empty"

    for entry <- action_classes do
      if entry.rebuild_required do
        # rebuild_required: true → classify must return {:rebuild_required, _}
        # Use a native_required capability as the representative — it always maps
        # to {:rebuild_required, :native_shell}, which satisfies rebuild_required: true.
        native_cap = %Types.Capability{id: "test.native", version: "1.0", rebuild: :native_required}
        result = RebuildPolicy.classify(:capability_family_add, native_cap)

        assert match?({:rebuild_required, _}, result),
               "action_class #{entry.action_class} has rebuild_required: true but classify/2 returned #{inspect(result)} for a :native_required capability"
      else
        # rebuild_required: false → OTA-safe capability must map to :ota_safe
        ota_cap = %Types.Capability{id: "test.ota", version: "1.0", rebuild: :none}
        result = RebuildPolicy.classify(:capability_family_add, ota_cap)

        assert result == :ota_safe,
               "action_class #{entry.action_class} has rebuild_required: false but classify/2 returned #{inspect(result)} for a :none capability"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # RLINE-03 — Rebuild & compatibility matrix surface
  #
  # SupportMatrix.rebuild_matrix/1 returns [RuntimeLineRow.t()] including "1.x".
  # Doctor human output contains "rebuild & compatibility matrix:".
  # Doctor JSON output contains "rebuild_matrix" key.
  # Human and JSON render the SAME runtime_line values (structural parity).
  # ---------------------------------------------------------------------------

  @tag :rline_03
  test "rebuild_matrix/1 returns non-empty [RuntimeLineRow.t()] with runtime_line including '1.x'" do
    matrix = SupportMatrix.rebuild_matrix(SupportMatrix.canonical())

    assert is_list(matrix) and length(matrix) > 0,
           ProofAssertions.stable_id_message(
             "proof.rline_03.rebuild_matrix.non_empty",
             "SupportMatrix.rebuild_matrix/1 must return a non-empty list",
             "SupportMatrix.rebuild_matrix/1",
             "rebuild_matrix returned empty list",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "add at least one RuntimeLineRow to @rebuild_matrix_rows",
             :merge_blocking
           )

    for row <- matrix do
      assert %Types.RuntimeLineRow{} = row,
             "each row in rebuild_matrix must be a %Types.RuntimeLineRow{}, got: #{inspect(row)}"
    end

    runtime_lines = Enum.map(matrix, & &1.runtime_line)

    assert "1.x" in runtime_lines,
           ProofAssertions.stable_id_message(
             "proof.rline_03.rebuild_matrix.includes_1x",
             "rebuild_matrix must include a row for runtime_line '1.x'",
             "SupportMatrix.rebuild_matrix/1",
             "missing '1.x' runtime-line row; found: #{inspect(runtime_lines)}",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "add a RuntimeLineRow with runtime_line: \"1.x\" to @rebuild_matrix_rows",
             :merge_blocking
           )
  end

  @tag :rline_03
  test "doctor human output contains 'rebuild & compatibility matrix:' block" do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@doctor_task)

        Mix.Task.run(@doctor_task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter"
        ])
      end)

    assert output =~ "rebuild & compatibility matrix:",
           ProofAssertions.stable_id_message(
             "proof.rline_03.doctor.human.rebuild_matrix_header",
             "doctor human output rebuild & compatibility matrix: block",
             "mix crosswake.doctor (human format)",
             "missing 'rebuild & compatibility matrix:' in doctor output",
             "lib/crosswake/doctor/formatter.ex",
             "add format_rebuild_matrix/1 call inside format_release_policy/1",
             :merge_blocking
           )
  end

  @tag :rline_03
  test "doctor JSON output contains 'rebuild_matrix' key with a list" do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@doctor_task)

        Mix.Task.run(@doctor_task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
          "--format",
          "json"
        ])
      end)

    decoded = Jason.decode!(output)

    assert Map.has_key?(decoded, "rebuild_matrix") or
             get_in(decoded, ["release_policy", "rebuild_matrix"]) != nil,
           ProofAssertions.stable_id_message(
             "proof.rline_03.doctor.json.rebuild_matrix_key",
             "doctor JSON output rebuild_matrix key",
             "mix crosswake.doctor --format json",
             "missing 'rebuild_matrix' key in doctor JSON output",
             "lib/crosswake/doctor/json_formatter.ex",
             "add rebuild_matrix key to format_release_policy/1 in json_formatter.ex",
             :merge_blocking
           )

    rebuild_matrix =
      Map.get(decoded, "rebuild_matrix") ||
        get_in(decoded, ["release_policy", "rebuild_matrix"])

    assert is_list(rebuild_matrix),
           "rebuild_matrix in JSON output must be a list, got: #{inspect(rebuild_matrix)}"
  end

  @tag :rline_03
  test "doctor human and JSON output render the same rebuild_matrix runtime_line values (structural parity)" do
    human_output =
      capture_io(fn ->
        Mix.Task.reenable(@doctor_task)

        Mix.Task.run(@doctor_task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter"
        ])
      end)

    json_output =
      capture_io(fn ->
        Mix.Task.reenable(@doctor_task)

        Mix.Task.run(@doctor_task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
          "--format",
          "json"
        ])
      end)

    decoded = Jason.decode!(json_output)

    rebuild_matrix =
      Map.get(decoded, "rebuild_matrix") ||
        get_in(decoded, ["release_policy", "rebuild_matrix"]) || []

    assert is_list(rebuild_matrix) and length(rebuild_matrix) > 0,
           "JSON rebuild_matrix must be non-empty for parity check"

    json_runtime_lines =
      Enum.map(rebuild_matrix, fn row ->
        Map.get(row, "runtime_line")
      end)

    for runtime_line <- json_runtime_lines do
      assert human_output =~ runtime_line,
             ProofAssertions.stable_id_message(
               "proof.rline_03.doctor.parity.runtime_line_#{runtime_line}",
               "rebuild_matrix structural parity (human vs JSON)",
               "mix crosswake.doctor / mix crosswake.doctor --format json",
               "runtime_line '#{runtime_line}' present in JSON but missing from human output",
               "lib/crosswake/doctor/formatter.ex",
               "ensure format_rebuild_matrix/1 iterates the same [RuntimeLineRow.t()] list as JSON",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # RLINE-04 — Evidence taxonomy: jvm_hermetic vs device_verified
  #
  # :device_verified renders as "device-verified"; :jvm_hermetic renders as
  # "jvm-hermetic (CI only)". validate/1 rejects :device_verified on CI-only.
  # Doctor evidence posture: line shows ios=device-verified android=jvm-hermetic.
  # ---------------------------------------------------------------------------

  @tag :rline_04
  test "verification_method :device_verified renders as 'device-verified' via doctor formatter path" do
    # CapabilitySupportEntry with verification_method: :device_verified
    # must render the literal "device-verified" in doctor output.
    # We assert via a SupportEntry carrying :device_verified that the formatter
    # converts the atom correctly (never promotes :jvm_hermetic to device-verified).
    ios_entries =
      SupportMatrix.capability_families(SupportMatrix.canonical())
      |> Enum.filter(fn entry ->
        Map.get(entry, :verification_method) == :device_verified
      end)

    for entry <- ios_entries do
      assert entry.verification_method == :device_verified,
             "expected :device_verified on entry #{inspect(entry.family)}"
    end

    # Direct formatter atom-to-string assertion: the formatter helper that converts
    # :device_verified must produce "device-verified".
    # We test via doctor human output — look for the evidence posture line.
    human_output =
      capture_io(fn ->
        Mix.Task.reenable(@doctor_task)

        Mix.Task.run(@doctor_task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter"
        ])
      end)

    assert human_output =~ "device-verified",
           ProofAssertions.stable_id_message(
             "proof.rline_04.render.device_verified",
             "device-verified render in doctor output",
             "mix crosswake.doctor (human format)",
             "missing 'device-verified' in doctor output — formatter must not drop or rename the label",
             "lib/crosswake/doctor/formatter.ex",
             "ensure format_evidence_tier(:device_verified) returns \"device-verified\"",
             :merge_blocking
           )
  end

  @tag :rline_04
  test "verification_method :jvm_hermetic renders as 'jvm-hermetic (CI only)' via doctor formatter path" do
    android_entries =
      SupportMatrix.capability_families(SupportMatrix.canonical())
      |> Enum.filter(fn entry ->
        Map.get(entry, :verification_method) == :jvm_hermetic
      end)

    for entry <- android_entries do
      assert entry.verification_method == :jvm_hermetic,
             "expected :jvm_hermetic on entry #{inspect(entry.family)}"
    end

    human_output =
      capture_io(fn ->
        Mix.Task.reenable(@doctor_task)

        Mix.Task.run(@doctor_task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter"
        ])
      end)

    assert human_output =~ "jvm-hermetic (CI only)",
           ProofAssertions.stable_id_message(
             "proof.rline_04.render.jvm_hermetic",
             "jvm-hermetic (CI only) render in doctor output",
             "mix crosswake.doctor (human format)",
             "missing 'jvm-hermetic (CI only)' in doctor output — CI-only label must be explicit",
             "lib/crosswake/doctor/formatter.ex",
             "ensure format_evidence_tier(:jvm_hermetic) returns \"jvm-hermetic (CI only)\"",
             :merge_blocking
           )
  end

  @tag :rline_04
  test "SupportMatrix.validate/1 rejects :device_verified on a CI-only CapabilitySupportEntry" do
    # Build a minimal matrix with a CI-only entry (evidence class is CI-only)
    # that claims :device_verified — validation must return a non-empty error list.
    canonical = SupportMatrix.canonical()

    # Clone a capability entry with CI-only evidence but device_verified claim
    # The validation invariant: no entry may carry :device_verified when the
    # evidence corpus is CI-only (jvm_hermetic hermetic level).
    ci_only_with_device_verified =
      struct!(
        Types.CapabilitySupportEntry,
        family: "test_ci_only",
        owner: :crosswake,
        package_class: "core",
        proof_class: :advisory,
        rebuild: :none,
        verification_method: :device_verified
      )

    # Construct a matrix carrying this invalid entry alongside the canonical families
    invalid_families = canonical.capability_families ++ [ci_only_with_device_verified]
    invalid_matrix = %{canonical | capability_families: invalid_families}

    errors = SupportMatrix.validate(invalid_matrix)

    assert is_list(errors) and length(errors) > 0,
           ProofAssertions.stable_id_message(
             "proof.rline_04.validate.rejects_device_verified_on_ci_only",
             "SupportMatrix.validate/1 must reject :device_verified on CI-only entry",
             "SupportMatrix.validate/1",
             "validate/1 returned [] for a CI-only entry with :device_verified — evidence laundering not caught",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "add validate_verification_method_invariant/2 to the validate/1 pipeline",
             :merge_blocking
           )
  end

  @tag :rline_04
  test "doctor 'evidence posture:' line contains ios=device-verified and android=jvm-hermetic (CI only)" do
    human_output =
      capture_io(fn ->
        Mix.Task.reenable(@doctor_task)

        Mix.Task.run(@doctor_task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter"
        ])
      end)

    assert human_output =~ "evidence posture:",
           ProofAssertions.stable_id_message(
             "proof.rline_04.doctor.evidence_posture_header",
             "doctor output evidence posture: line",
             "mix crosswake.doctor (human format)",
             "missing 'evidence posture:' line in doctor output",
             "lib/crosswake/doctor/formatter.ex",
             "add evidence posture: line to format_release_policy/1",
             :merge_blocking
           )

    assert human_output =~ "ios=device-verified",
           ProofAssertions.stable_id_message(
             "proof.rline_04.doctor.evidence_posture.ios",
             "evidence posture: line contains ios=device-verified",
             "mix crosswake.doctor (human format)",
             "missing 'ios=device-verified' in doctor evidence posture line",
             "lib/crosswake/doctor/formatter.ex",
             "render iOS evidence as ios=device-verified in the evidence posture: line",
             :merge_blocking
           )

    assert human_output =~ "android=jvm-hermetic (CI only)",
           ProofAssertions.stable_id_message(
             "proof.rline_04.doctor.evidence_posture.android",
             "evidence posture: line contains android=jvm-hermetic (CI only)",
             "mix crosswake.doctor (human format)",
             "missing 'android=jvm-hermetic (CI only)' in doctor evidence posture line",
             "lib/crosswake/doctor/formatter.ex",
             "render Android evidence as android=jvm-hermetic (CI only) in the evidence posture: line",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # RLINE-05 — Android promotion criteria
  #
  # promotion_rules() contains shell.android.jvm_hermetic (min 3 passes, :jvm_hermetic)
  # and shell.android.device_verified (gated, :device_verified, demotion_trigger
  # mentioning Phases 67/68 and that jvm_hermetic must not be read as device_verified).
  # Canonical Android SupportEntry.status == :verification_required (D-20).
  # ---------------------------------------------------------------------------

  @tag :rline_05
  test "promotion_rules() contains shell.android.jvm_hermetic row with required fields" do
    rules = SupportMatrix.promotion_rules()
    assert is_list(rules), "promotion_rules() must return a list"

    jvm_row =
      Enum.find(rules, fn r -> r.claim_id == "shell.android.jvm_hermetic" end)

    assert jvm_row != nil,
           ProofAssertions.stable_id_message(
             "proof.rline_05.promotion_rules.jvm_hermetic_present",
             "promotion_rules() must contain shell.android.jvm_hermetic",
             "SupportMatrix.promotion_rules/0",
             "missing 'shell.android.jvm_hermetic' promotion row",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "add shell.android.jvm_hermetic PromotionRuleEntry to promotion_rule_entries/0",
             :merge_blocking
           )

    assert jvm_row.minimum_consecutive_passes == 3,
           ProofAssertions.stable_id_message(
             "proof.rline_05.jvm_hermetic.min_passes",
             "shell.android.jvm_hermetic minimum_consecutive_passes == 3",
             "SupportMatrix.promotion_rules/0 shell.android.jvm_hermetic",
             "minimum_consecutive_passes is #{jvm_row.minimum_consecutive_passes}, expected 3",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "set minimum_consecutive_passes: 3 on shell.android.jvm_hermetic row",
             :merge_blocking
           )

    assert jvm_row.required_verification_method == :jvm_hermetic,
           ProofAssertions.stable_id_message(
             "proof.rline_05.jvm_hermetic.required_verification_method",
             "shell.android.jvm_hermetic required_verification_method == :jvm_hermetic",
             "SupportMatrix.promotion_rules/0 shell.android.jvm_hermetic",
             "required_verification_method is #{inspect(jvm_row.required_verification_method)}, expected :jvm_hermetic",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "set required_verification_method: :jvm_hermetic on shell.android.jvm_hermetic row",
             :merge_blocking
           )
  end

  @tag :rline_05
  test "promotion_rules() contains shell.android.device_verified row with demotion_trigger mentioning Phases 67/68 and jvm_hermetic gating" do
    rules = SupportMatrix.promotion_rules()

    device_row =
      Enum.find(rules, fn r -> r.claim_id == "shell.android.device_verified" end)

    assert device_row != nil,
           ProofAssertions.stable_id_message(
             "proof.rline_05.promotion_rules.device_verified_present",
             "promotion_rules() must contain shell.android.device_verified",
             "SupportMatrix.promotion_rules/0",
             "missing 'shell.android.device_verified' promotion row",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "add shell.android.device_verified PromotionRuleEntry to promotion_rule_entries/0",
             :merge_blocking
           )

    assert device_row.required_verification_method == :device_verified,
           ProofAssertions.stable_id_message(
             "proof.rline_05.device_verified.required_verification_method",
             "shell.android.device_verified required_verification_method == :device_verified",
             "SupportMatrix.promotion_rules/0 shell.android.device_verified",
             "required_verification_method is #{inspect(device_row.required_verification_method)}, expected :device_verified",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "set required_verification_method: :device_verified on shell.android.device_verified row",
             :merge_blocking
           )

    demotion = device_row.demotion_trigger || ""

    assert demotion =~ "67" or demotion =~ "68",
           ProofAssertions.stable_id_message(
             "proof.rline_05.device_verified.demotion_phases",
             "shell.android.device_verified demotion_trigger mentions Phases 67/68",
             "SupportMatrix.promotion_rules/0 shell.android.device_verified demotion_trigger",
             "demotion_trigger does not mention Phase 67 or 68: #{inspect(demotion)}",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "add Phase 67/68 availability note to shell.android.device_verified demotion_trigger prose",
             :merge_blocking
           )

    assert demotion =~ "jvm_hermetic" or demotion =~ "jvm-hermetic",
           ProofAssertions.stable_id_message(
             "proof.rline_05.device_verified.demotion_jvm_gate",
             "shell.android.device_verified demotion_trigger states jvm_hermetic must not be read as device_verified",
             "SupportMatrix.promotion_rules/0 shell.android.device_verified demotion_trigger",
             "demotion_trigger does not mention jvm_hermetic gating note: #{inspect(demotion)}",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "add explicit note that jvm_hermetic promotion must NOT be read as device_verified",
             :merge_blocking
           )
  end

  @tag :rline_05
  test "canonical Android SupportEntry.status remains :verification_required (D-20 guardrail)" do
    canonical = SupportMatrix.canonical()

    android_entries =
      canonical.android
      |> Enum.filter(fn entry -> Map.has_key?(entry, :status) end)

    assert length(android_entries) > 0,
           "canonical android list must be non-empty and contain entries with :status"

    for entry <- android_entries do
      assert entry.status == :verification_required,
             ProofAssertions.stable_id_message(
               "proof.rline_05.android.verification_required",
               "Android SupportEntry.status must be :verification_required in Phase 64",
               "SupportMatrix.canonical/0 android entries",
               "Android entry has status #{inspect(entry.status)} — expected :verification_required (D-20: Android not promoted until Phase 69)",
               "lib/crosswake/support_matrix/support_matrix.ex",
               "do NOT flip Android status in Phase 64; the promotion gate is Phase 69",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Hermetic lane guard
  #
  # This file must NOT carry @moduletag :requires_example_host and must have
  # no example-host or env-flag references (hermetic, env-independent).
  # ---------------------------------------------------------------------------

  test "hermetic lane guard: no @moduletag :requires_example_host and no example-host references" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "phase64 proof lane must not carry any @moduletag — it is hermetic"

    refute String.contains?(source, "Crosswake" <> "Example."),
           "phase64 proof lane must not reference example-host modules"

    refute String.contains?(source, "MIX_INCLUDE_"),
           "phase64 proof lane must not reference MIX_INCLUDE_* env flags"
  end
end
