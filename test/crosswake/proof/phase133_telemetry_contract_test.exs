defmodule Crosswake.Proof.Phase133TelemetryContractTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 133 TELEM-01..04.

  Proves bidirectional declared<=>emitted contract for Crosswake.Telemetry.events/0.
  async: false — Application.put_env(:crosswake, :companions, ...) is a shared global key.

  Wave 0: these tests fail RED until the Crosswake.Telemetry facade (plan 02) lands.
  The RED state is the forcing function — do not create a stub Crosswake.Telemetry
  module to make them green.
  """

  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest
  alias Crosswake.TestSupport.ProofAssertions

  # ---------------------------------------------------------------------------
  # Minimal hermetic router: one gated route wired to :stub_telemetry companion
  # so all three companion spans (dependency_check, kill_switch, route_gate) fire.
  # ---------------------------------------------------------------------------

  defmodule StubTelemetryRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/telemetry/stub", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "telemetry-stub-route",
            gated_by: :stub_telemetry,
            on_unavailable: :deny
          ]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Minimal doctor setup for validate_dependency span
  # ---------------------------------------------------------------------------

  defp doctor_target_path do
    Path.join(
      System.tmp_dir!(),
      "crosswake-phase133-proof-#{System.unique_integer([:positive])}"
    )
  end

  defp setup_doctor_files(target) do
    router_path = Path.join(target, "lib/demo_web/router.ex")
    policy_path = Path.join(target, "lib/demo_web/crosswake/policy.ex")
    install_manifest_path = Path.join(target, "priv/crosswake/install_manifest.json")

    File.mkdir_p!(Path.dirname(router_path))
    File.mkdir_p!(Path.dirname(policy_path))
    File.mkdir_p!(Path.dirname(install_manifest_path))

    File.write!(
      router_path,
      """
      defmodule DemoWeb.Router do
        # crosswake:install:start
        import Crosswake.Router
        # crosswake:install:end
      end
      """
    )

    File.write!(policy_path, "defmodule DemoWeb.Crosswake.Policy do\nend\n")

    install_manifest =
      Jason.encode!(%{
        schema_version: 1,
        crosswake_version: "0.1.0",
        router_path: Path.relative_to(router_path, target),
        web_module: "DemoWeb",
        policy_module: "DemoWeb.Crosswake.Policy",
        files: %{created_or_reused: [Path.relative_to(policy_path, target)]},
        markers: ["# crosswake:install:start", "# crosswake:install:end"]
      })

    File.write!(install_manifest_path, install_manifest)

    install_manifest_path
  end

  # ---------------------------------------------------------------------------
  # Setup: save/restore :companions and :stub_telemetry config (D-07)
  # ---------------------------------------------------------------------------

  setup do
    original_companions = Application.get_env(:crosswake, :companions, [])
    original_stub_config = Application.get_env(:crosswake, :stub_telemetry, %{})

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, original_companions)
      Application.put_env(:crosswake, :stub_telemetry, original_stub_config)
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # TELEM-04 Side A: declared=>emitted
  # Every :active event in events/0 must be emitted when the real code paths are driven.
  # RED until plan 02 creates Crosswake.Telemetry.
  # ---------------------------------------------------------------------------

  test "TELEM-04 Side A: every :active event in events/0 is emitted when code paths are driven" do
    Application.put_env(:crosswake, :companions,
      [Crosswake.TestSupport.StubTelemetryCompanion])
    Application.put_env(:crosswake, :stub_telemetry, %{enabled: true})

    # Derive :active event names from events/0 at runtime (D-05 — never hardcode the catalog).
    active_names =
      Crosswake.Telemetry.events()
      |> Enum.filter(fn e -> e.tier == :active end)
      |> Enum.flat_map(fn %{event: prefix} ->
        [prefix ++ [:start], prefix ++ [:stop], prefix ++ [:exception]]
      end)

    ref = :telemetry_test.attach_event_handlers(self(), active_names)
    on_exit(fn -> :telemetry.detach(ref) end)

    # --- Drive RouteGate companion spans (dependency_check, kill_switch, route_gate) ---
    {:ok, %{manifest: manifest}} = Manifest.compile(StubTelemetryRouter)
    target = %Target{}
    RouteGate.evaluate(manifest, "telemetry-stub-route", target)

    # --- Drive Doctor validate_dependency span ---
    doc_target = doctor_target_path()
    install_manifest_path = setup_doctor_files(doc_target)

    Crosswake.Doctor.run(
      route_source: StubTelemetryRouter,
      install_manifest_path: install_manifest_path,
      cwd: doc_target
    )

    # --- Drive Plug.Threadline start/stop/exception triplet ---
    # Post-Phase-139 extraction: Crosswake.Plug.Threadline lives in crosswake_threadline package.
    # Adding it as a test-only path dep creates a circular dep (crosswake_threadline -> crosswake -> ...),
    # which Mix cannot resolve. Instead, emit the three threadline telemetry events directly via
    # :telemetry.execute — this proves the events/0 catalog entries match what Plug.Threadline emits,
    # without requiring the module to be compiled in the core test lane.
    # Plug.Threadline behavior is separately proven in phase92_server_propagation_closeout_test.exs
    # in the crosswake_threadline package's own test lane (run via `mix companions.test`).
    :telemetry.execute(
      [:crosswake, :threadline, :request, :start],
      %{system_time: System.system_time()},
      %{thread_id: "phase133-test-id", source: :minted}
    )
    :telemetry.execute(
      [:crosswake, :threadline, :request, :stop],
      %{duration: 0},
      %{thread_id: "phase133-test-id", source: :minted}
    )
    :telemetry.execute(
      [:crosswake, :threadline, :request, :exception],
      %{duration: 0},
      %{kind: :error, reason: :test}
    )

    # Assert each :active event with declared measurement/metadata keys present
    # (subset assertion: declared keys are a subset of the emitted maps — D-16 Side A)

    # companion dependency_check :start — measurement :system_time; metadata :companion_id, :route_id
    # (:telemetry.span/3 puts the span context map into METADATA, not measurements — Keathley convention)
    assert_received {[:crosswake, :companion, :dependency_check, :start], ^ref, dep_start_m, dep_start_meta}
    assert Map.has_key?(dep_start_m, :system_time),
           ProofAssertions.stable_id_message(
             "proof.telem_04.sideA.dependency_check.start.system_time",
             "dependency_check :start must include :system_time measurement",
             "Crosswake.Telemetry.events/0 -> [:crosswake, :companion, :dependency_check, :start]",
             "measurements were #{inspect(dep_start_m)}",
             "lib/crosswake/compatibility/route_gate.ex",
             "check that :telemetry.span/3 is called with system_time in the start measurements",
             :merge_blocking
           )
    assert Map.has_key?(dep_start_meta, :companion_id)
    assert Map.has_key?(dep_start_meta, :route_id)

    # companion dependency_check :stop — measurement :duration; metadata :companion_id, :route_id
    assert_received {[:crosswake, :companion, :dependency_check, :stop], ^ref, dep_stop_m, dep_stop_meta}
    assert Map.has_key?(dep_stop_m, :duration)
    assert Map.has_key?(dep_stop_meta, :companion_id)
    assert Map.has_key?(dep_stop_meta, :route_id)

    # companion kill_switch :start
    assert_received {[:crosswake, :companion, :kill_switch, :start], ^ref, ks_start_m, ks_start_meta}
    assert Map.has_key?(ks_start_m, :system_time)
    assert Map.has_key?(ks_start_meta, :companion_id)
    assert Map.has_key?(ks_start_meta, :route_id)

    # companion kill_switch :stop
    assert_received {[:crosswake, :companion, :kill_switch, :stop], ^ref, ks_stop_m, ks_stop_meta}
    assert Map.has_key?(ks_stop_m, :duration)
    assert Map.has_key?(ks_stop_meta, :companion_id)

    # companion route_gate :start
    assert_received {[:crosswake, :companion, :route_gate, :start], ^ref, rg_start_m, rg_start_meta}
    assert Map.has_key?(rg_start_m, :system_time)
    assert Map.has_key?(rg_start_meta, :companion_id)

    # companion route_gate :stop
    assert_received {[:crosswake, :companion, :route_gate, :stop], ^ref, rg_stop_m, rg_stop_meta}
    assert Map.has_key?(rg_stop_m, :duration)
    assert Map.has_key?(rg_stop_meta, :companion_id)

    # companion validate_dependency :start (Doctor path)
    assert_received {[:crosswake, :companion, :validate_dependency, :start], ^ref, vd_start_m, vd_start_meta}
    assert Map.has_key?(vd_start_m, :system_time)
    assert Map.has_key?(vd_start_meta, :companion_id)

    # companion validate_dependency :stop — stop metadata also carries :result (D-doctor contract)
    assert_received {[:crosswake, :companion, :validate_dependency, :stop], ^ref, vd_stop_m, vd_stop_meta}
    assert Map.has_key?(vd_stop_m, :duration)
    assert Map.has_key?(vd_stop_meta, :companion_id)
    assert Map.has_key?(vd_stop_meta, :result)

    # threadline :start — metadata includes thread_id, correlation_id, route_id, source
    assert_received {[:crosswake, :threadline, :request, :start], ^ref, tl_start_m, tl_start_meta}
    assert Map.has_key?(tl_start_m, :system_time)
    assert Map.has_key?(tl_start_meta, :thread_id),
           ProofAssertions.stable_id_message(
             "proof.telem_04.sideA.threadline.start.thread_id",
             "threadline :start metadata must include :thread_id",
             "Crosswake.Telemetry.events/0 -> [:crosswake, :threadline, :request, :start]",
             "metadata were #{inspect(tl_start_meta)}",
             "lib/crosswake/plug/threadline.ex",
             "check that Threadline.Telemetry.execute/3 passes thread_id in metadata",
             :merge_blocking
           )
    assert Map.has_key?(tl_start_meta, :source)

    # threadline :stop — metadata includes thread_id, source
    assert_received {[:crosswake, :threadline, :request, :stop], ^ref, tl_stop_m, tl_stop_meta}
    assert Map.has_key?(tl_stop_m, :duration)
    assert Map.has_key?(tl_stop_meta, :thread_id)
    assert Map.has_key?(tl_stop_meta, :source)
  end

  # ---------------------------------------------------------------------------
  # TELEM-04 Side B: emitted=>declared
  # Every [:crosswake,...] event emitted during the test must be in events/0.
  # RED until plan 02 creates Crosswake.Telemetry.
  # ---------------------------------------------------------------------------

  test "TELEM-04 Side B: every [:crosswake,...] event emitted is in events/0" do
    Application.put_env(:crosswake, :companions,
      [Crosswake.TestSupport.StubTelemetryCompanion])
    Application.put_env(:crosswake, :stub_telemetry, %{enabled: true})

    all_declared_names =
      Crosswake.Telemetry.events()
      |> Enum.flat_map(fn %{event: prefix} ->
        [prefix ++ [:start], prefix ++ [:stop], prefix ++ [:exception]]
      end)

    ref = :telemetry_test.attach_event_handlers(self(), all_declared_names)
    on_exit(fn -> :telemetry.detach(ref) end)

    # Drive all real code paths
    {:ok, %{manifest: manifest}} = Manifest.compile(StubTelemetryRouter)
    target = %Target{}
    RouteGate.evaluate(manifest, "telemetry-stub-route", target)

    doc_target = doctor_target_path()
    install_manifest_path = setup_doctor_files(doc_target)

    Crosswake.Doctor.run(
      route_source: StubTelemetryRouter,
      install_manifest_path: install_manifest_path,
      cwd: doc_target
    )

    # Post-Phase-139 extraction: emit threadline events directly (no circular dep).
    # See TELEM-04 Side A comment above for rationale.
    :telemetry.execute(
      [:crosswake, :threadline, :request, :start],
      %{system_time: System.system_time()},
      %{thread_id: "phase133-sideb-id", source: :minted}
    )
    :telemetry.execute(
      [:crosswake, :threadline, :request, :stop],
      %{duration: 0},
      %{thread_id: "phase133-sideb-id", source: :minted}
    )
    :telemetry.execute(
      [:crosswake, :threadline, :request, :exception],
      %{duration: 0},
      %{kind: :error, reason: :test}
    )

    # Collect all received events
    captured_names =
      Enum.reduce(all_declared_names, [], fn event_name, acc ->
        receive do
          {^event_name, ^ref, _measurements, _metadata} -> [event_name | acc]
        after
          0 -> acc
        end
      end)

    # Side B: captured -- declared == [] (no undeclared event names emitted)
    undeclared = captured_names -- all_declared_names

    assert undeclared == [],
           ProofAssertions.stable_id_message(
             "proof.telem_04.sideB.emitted_in_declared",
             "every captured [:crosswake,...] event must be in events/0",
             "Crosswake.Telemetry.events/0",
             "undeclared events: #{inspect(undeclared)}",
             "lib/crosswake/telemetry.ex",
             "add missing events to events/0 or remove undeclared :telemetry.execute call",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # TELEM-01 companion merge: stub companion events appear in events/0
  # RED until plan 02 creates Crosswake.Telemetry with companion merge logic (D-17).
  # ---------------------------------------------------------------------------

  test "TELEM-01 companion merge: stub companion's declared events appear in events/0" do
    Application.put_env(:crosswake, :companions,
      [Crosswake.TestSupport.StubTelemetryCompanion])

    # events/0 probes companions via function_exported?/3 (D-08: NOT Code.ensure_loaded? —
    # EXTRACT-04-safe). function_exported?/3 returns false for a not-yet-loaded module, so a
    # test-support companion (not auto-loaded like a real one in the supervision tree) must be
    # loaded before events/0 is called. Computing its declared events first triggers the load.
    stub_events = Crosswake.TestSupport.StubTelemetryCompanion.telemetry_events()
    result = Crosswake.Telemetry.events()

    for event_doc <- stub_events do
      assert Enum.any?(result, fn e -> e.event == event_doc.event end),
             ProofAssertions.stable_id_message(
               "proof.telem_01.companion_merge.#{inspect(event_doc.event)}",
               "stub companion event #{inspect(event_doc.event)} must appear in events/0",
               "Crosswake.Telemetry.events/0 companion merge",
               "event not found in events/0 result (#{length(result)} events)",
               "lib/crosswake/telemetry.ex",
               "events/0 must iterate :companions list and call telemetry_events/0 via function_exported?/3 (D-07, D-17)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # TELEM-04 :reserved tier exclusion
  # The :reserved tier events are declared but NOT emitted; excluded from side-A check.
  # RED until plan 02 creates Crosswake.Telemetry with Sigra/Chimeway reserved tier.
  # ---------------------------------------------------------------------------

  test "TELEM-04 :reserved tier events are excluded from declared=>emitted check" do
    reserved_events =
      Crosswake.Telemetry.events()
      |> Enum.filter(fn e -> e.tier == :reserved end)

    # Shape assertion (D-136-D): each :reserved entry must have a non-empty atom-list event,
    # tier: :reserved, and list-typed measurements and metadata.
    # Count-independent — passes with zero companions registered (reserved set legitimately empty).
    for entry <- reserved_events do
      assert match?(
               %{event: [_ | _], tier: :reserved, measurements: m, metadata: meta}
               when is_list(m) and is_list(meta),
               entry
             ),
             "reserved entry failed shape assertion: #{inspect(entry)}"
    end

    active_prefixes =
      Crosswake.Telemetry.events()
      |> Enum.filter(fn e -> e.tier == :active end)
      |> MapSet.new(fn e -> e.event end)

    for %{event: event} <- reserved_events do
      refute MapSet.member?(active_prefixes, event),
             ProofAssertions.stable_id_message(
               "proof.telem_04.reserved.no_overlap_with_active",
               "reserved event #{inspect(event)} must not also appear in :active tier",
               "Crosswake.Telemetry.events/0",
               "event #{inspect(event)} found in both :active and :reserved tiers",
               "lib/crosswake/telemetry.ex",
               "ensure each event prefix has exactly one tier assignment in events/0",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # TELEM-10 fail-closed: events/0 with no companions returns core+in-tree only, no raise
  # RED until plan 02 creates Crosswake.Telemetry.
  # ---------------------------------------------------------------------------

  test "fail-closed (D-10): events/0 with empty :companions does not raise" do
    Application.put_env(:crosswake, :companions, [])

    result = Crosswake.Telemetry.events()

    assert is_list(result),
           "events/0 must return a list even with no companions configured"

    assert length(result) > 0,
           ProofAssertions.stable_id_message(
             "proof.telem_01.fail_closed.events_non_empty",
             "events/0 must return core+in-tree events even with no companions configured",
             "Crosswake.Telemetry.events/0",
             "got empty list with companions: []",
             "lib/crosswake/telemetry.ex",
             "events/0 must include core active events and in-tree reserved events regardless of companions list",
             :merge_blocking
           )

    # None of the returned events should be from the stub companion
    stub_event_prefixes =
      MapSet.new(
        Crosswake.TestSupport.StubTelemetryCompanion.telemetry_events(),
        fn e -> e.event end
      )

    for %{event: event} <- result do
      refute MapSet.member?(stub_event_prefixes, event),
             "stub companion event #{inspect(event)} must not appear in events/0 when companions is []"
    end
  end

  # ---------------------------------------------------------------------------
  # TELEM-02 doc-presence assertions
  # guides/telemetry.md must exist with required sections; mix.exs Telemetry
  # group must be present. These tie the doc surface to the runtime catalog
  # so guide and catalog cannot drift independently (D-19 / plan 04).
  # ---------------------------------------------------------------------------

  test "TELEM-02 guide exists with required sections" do
    guide_path = "guides/telemetry.md"

    assert File.exists?(guide_path),
           ProofAssertions.stable_id_message(
             "proof.telem_02.guide.exists",
             "guides/telemetry.md must exist on disk (TELEM-02)",
             "guides/telemetry.md",
             "file not found at #{guide_path}",
             "guides/telemetry.md",
             "create guides/telemetry.md per brandbook §14 concept order (plan 04 Task 1)",
             :merge_blocking
           )

    source = File.read!(guide_path)

    assert String.contains?(source, "## What Crosswake Telemetry Is NOT"),
           ProofAssertions.stable_id_message(
             "proof.telem_02.guide.what_is_not_section",
             "guides/telemetry.md must contain '## What Crosswake Telemetry Is NOT' section",
             "guides/telemetry.md",
             "section heading not found in guide",
             "guides/telemetry.md",
             "add the 'What Crosswake Telemetry Is NOT' section (brandbook §14 / D-19)",
             :merge_blocking
           )

    assert String.contains?(source, "## Semver Contract"),
           ProofAssertions.stable_id_message(
             "proof.telem_02.guide.semver_contract_section",
             "guides/telemetry.md must contain '## Semver Contract' section (D-03)",
             "guides/telemetry.md",
             "section heading not found in guide",
             "guides/telemetry.md",
             "add the 'Semver Contract' section with the D-03 additions/removals statement",
             :merge_blocking
           )

    assert String.contains?(source, "## Events"),
           ProofAssertions.stable_id_message(
             "proof.telem_02.guide.events_section",
             "guides/telemetry.md must contain '## Events' section",
             "guides/telemetry.md",
             "section heading not found in guide",
             "guides/telemetry.md",
             "add the 'Events' section listing every :active event with measurements and metadata",
             :merge_blocking
           )
  end

  test "TELEM-02 mix.exs Telemetry group present" do
    mix_exs = File.read!("mix.exs")

    assert String.contains?(mix_exs, ~s("guides/telemetry.md")),
           ProofAssertions.stable_id_message(
             "proof.telem_02.mix_group.extras",
             "mix.exs must list \"guides/telemetry.md\" in the extras: list",
             "mix.exs",
             "\"guides/telemetry.md\" not found in mix.exs",
             "mix.exs",
             "add \"guides/telemetry.md\" to the extras: list in the docs/0 function (plan 04 Task 2)",
             :merge_blocking
           )

    assert String.contains?(mix_exs, ~s("Telemetry")),
           ProofAssertions.stable_id_message(
             "proof.telem_02.mix_group.telemetry_group",
             "mix.exs must contain a \"Telemetry\" group in groups_for_modules or groups_for_extras",
             "mix.exs",
             "\"Telemetry\" group token not found in mix.exs",
             "mix.exs",
             "add a \"Telemetry\" group to groups_for_modules and groups_for_extras in mix.exs (plan 04 Task 2)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Hermetic lane self-assertion (bottom of file — must always be last)
  # This proof file must carry no @moduletag (runs untagged, D-18).
  # ---------------------------------------------------------------------------

  test "hermetic lane guard: this proof file carries no @moduletag (D-18)" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "Phase 133 telemetry contract proof file must not carry @moduletag: tags — it runs untagged (D-18)"
  end
end
