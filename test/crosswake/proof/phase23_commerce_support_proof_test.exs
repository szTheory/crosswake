
defmodule Crosswake.Proof.Phase23CommerceSupportProofTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for Phase 23 commerce support truth.

  Stitches the Phase 19-23 commerce contract surfaces together and asserts the
  invariants that the Phase 23 merge-blocking CI lane gates on:

  - Doctor `commerce_summary` surface keys and proof_class labels.
  - Stale/unknown freshness fail-closed as merge-blocking, not informational.
  - Support matrix commerce corridors carry proof_class, prerequisite_classes,
    and rebuild_requirement metadata.
  - Support matrix denial codes are a superset of doctor-emitted commerce
    corridor denial codes.
  - guides/commerce.md three-layer structure and explicit non-claims.
  - No provider-specific vocabulary leaks into merge-blocking proof
    surfaces outside of explicitly advisory or non-claim sections.
  - Human and JSON formatters render proof_class labels on commerce findings.

  This test is fully hermetic by design: it never hits the network, never
  launches a simulator, and never depends on a provider SDK. It runs against
  in-memory router fixtures, the canonical `Crosswake.SupportMatrix`, the
  doctor pipeline, and the checked-in `guides/commerce.md` artifact.
  """

  use ExUnit.Case, async: true

  alias Crosswake.Doctor
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter
  alias Crosswake.SupportMatrix

  @forbidden_provider_tokens [
    "store" <> "kit",
    "play" <> "_billing",
    "play" <> " " <> "billing",
    "revenue" <> "cat"
  ]

  @guide_path Path.join([File.cwd!(), "guides", "commerce.md"])

  defmodule PaywallCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
        live "/paywall", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "paywall",
            runtime: :live_view,
            commerce: [corridor: :subscription_default, role: :paywall_entry]
          ]
      end
    end
  end

  defmodule PurchaseCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :native_screen, offline: :unavailable, security: :sensitive do
        live "/buy", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "buy",
            runtime: :native_screen,
            commerce: [corridor: :subscription_default, role: :purchase_intent]
          ]
      end
    end
  end

  defmodule CommerceCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
        live "/billing", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "billing",
            runtime: :live_view,
            capabilities: ["purchase_intent"],
            commerce: [corridor: :subscription_default, role: :purchase_intent]
          ]
      end
    end
  end

  setup do
    target =
      Path.join(System.tmp_dir!(), "crosswake-phase23-proof-#{System.unique_integer([:positive])}")

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

    %{
      target: target,
      install_manifest_path: install_manifest_path
    }
  end

  # -- Doctor commerce_summary surface --

  test "doctor commerce_summary exposes the canonical keys for the merge-blocking lane", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :fresh
      )

    summary = report.commerce_summary

    assert is_map(summary)

    assert MapSet.new(Map.keys(summary)) ==
             MapSet.new([
               :corridors,
               :prerequisites,
               :snapshot_freshness,
               :proof_posture,
               :rebuild_requirements
             ])

    assert is_list(summary.corridors)
    assert is_map(summary.prerequisites)
    assert summary.snapshot_freshness in [:fresh, :stale, :unknown, :not_applicable]
    assert is_map(summary.proof_posture)
    assert Map.has_key?(summary.proof_posture, :merge_blocking)
    assert Map.has_key?(summary.proof_posture, :advisory)
    assert is_list(summary.rebuild_requirements)
  end

  test "every merge-blocking commerce finding carries proof_class :merge_blocking in its details", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :stale
      )

    commerce_findings =
      report.findings
      |> Enum.filter(fn finding ->
        String.starts_with?(finding.code, "commerce.") or
          finding.check in ["commerce_corridor", "commerce_summary"]
      end)

    assert commerce_findings != [],
           "expected at least one commerce finding from a route with a commerce corridor"

    # Every commerce finding carries a proof_class detail. The merge-blocking lane
    # asserts this directly; the support matrix mapping resolves the value.
    for finding <- commerce_findings do
      assert Map.has_key?(finding.details, :proof_class),
             "commerce finding #{finding.code} missing :proof_class in details"
    end

    merge_blocking_findings =
      Enum.filter(commerce_findings, fn finding ->
        Map.get(finding.details, :proof_class) in ["merge_blocking", :merge_blocking]
      end)

    assert merge_blocking_findings != [],
           "expected at least one merge_blocking commerce finding (stale snapshot)"
  end

  # -- Stale / unknown freshness fail-closed as merge-blocking --

  test "stale entitlement snapshot freshness emits a merge-blocking diagnostic (not informational)",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :stale
      )

    stale_finding =
      Enum.find(report.findings, &(&1.code == "commerce.entitlement.stale_snapshot"))

    assert stale_finding,
           "expected a commerce.entitlement.stale_snapshot finding when snapshot freshness is :stale"

    assert stale_finding.details[:proof_class] == "merge_blocking",
           "stale snapshot finding must carry proof_class merge_blocking, not informational/advisory"

    assert "commerce.entitlement.stale_snapshot" in report.commerce_summary.proof_posture.merge_blocking
  end

  test "unknown entitlement snapshot freshness defaults to fail-closed merge-blocking truth", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert report.commerce_summary.snapshot_freshness == :unknown,
           "default freshness when commerce routes exist must be :unknown, not :fresh"

    assert Enum.any?(
             report.findings,
             &(&1.code == "commerce.entitlement.stale_snapshot" and
                 &1.details[:proof_class] == "merge_blocking")
           ),
           "unknown freshness must produce a merge_blocking stale_snapshot finding"
  end

  # -- Support matrix commerce corridors completeness --

  test "every support matrix commerce corridor carries proof_class, prerequisite_classes, and rebuild_requirement metadata" do
    entries = SupportMatrix.commerce_corridors()

    assert length(entries) > 0,
           "support matrix must declare at least one commerce corridor entry"

    for entry <- entries do
      assert Map.has_key?(entry, :proof_class),
             "commerce corridor #{entry.corridor_role} missing :proof_class"

      assert entry.proof_class in [:merge_blocking, :advisory],
             "commerce corridor #{entry.corridor_role} proof_class must be :merge_blocking or :advisory"

      assert Map.has_key?(entry, :prerequisite_classes) and
               is_list(entry.prerequisite_classes) and entry.prerequisite_classes != [],
             "commerce corridor #{entry.corridor_role} prerequisite_classes must be a non-empty list"

      assert Map.has_key?(entry, :rebuild_requirement) and is_map(entry.rebuild_requirement),
             "commerce corridor #{entry.corridor_role} rebuild_requirement must be a map"

      assert Map.has_key?(entry.rebuild_requirement, :native_rebuild_required),
             "commerce corridor #{entry.corridor_role} rebuild_requirement missing :native_rebuild_required"

      assert Map.has_key?(entry.rebuild_requirement, :rebuild_trigger),
             "commerce corridor #{entry.corridor_role} rebuild_requirement missing :rebuild_trigger"
    end

    taxonomy = MapSet.new(SupportMatrix.commerce_corridor_prerequisite_taxonomy())

    for entry <- entries, prerequisite_class <- entry.prerequisite_classes do
      assert MapSet.member?(taxonomy, prerequisite_class),
             "commerce corridor #{entry.corridor_role} prerequisite_class #{inspect(prerequisite_class)} is not in canonical taxonomy"
    end
  end

  test "support matrix denial codes are a superset of doctor-emitted commerce corridor denial codes",
       %{target: target, install_manifest_path: install_manifest_path} do
    # Exercise the doctor against a router that triggers prerequisite_missing /
    # runtime_incompatible denial paths (the same shape used by phase 19 tests).
    report =
      Doctor.run(
        route_source: CommerceCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    doctor_denial_codes =
      report.findings
      |> Enum.filter(&(&1.check == "commerce_corridor"))
      |> Enum.map(& &1.code)
      |> MapSet.new()

    canonical_codes = MapSet.new(SupportMatrix.commerce_corridor_denial_codes())

    assert MapSet.subset?(doctor_denial_codes, canonical_codes),
           "doctor emitted commerce corridor codes #{inspect(MapSet.to_list(doctor_denial_codes))} are not a subset of canonical support matrix denial codes #{inspect(MapSet.to_list(canonical_codes))}"

    # And doctor surfaces non-trivial codes (we did not get an empty match by accident).
    assert MapSet.size(doctor_denial_codes) >= 1,
           "expected at least one commerce_corridor denial code from the fixture router"
  end

  # -- guides/commerce.md three-layer structure & non-claims --

  test "commerce guide publishes three explicit H2 layer headings (support truth / playbooks / non-claims)" do
    content = File.read!(@guide_path)

    assert content =~ ~r/^## Commerce Support Truth\s*$/m,
           "commerce guide missing Layer 1 heading `## Commerce Support Truth`"

    assert content =~ ~r/^## Reviewer And Storefront Playbooks\s*$/m,
           "commerce guide missing Layer 2 heading `## Reviewer And Storefront Playbooks`"

    assert content =~ ~r/^## Rough Edges And Non-Claims\s*$/m,
           "commerce guide missing Layer 3 heading `## Rough Edges And Non-Claims`"
  end

  test "commerce guide non-claims section explicitly names StoreKit and Play Billing as not shipped" do
    content = File.read!(@guide_path)

    non_claims_section =
      content
      |> String.split("## Rough Edges And Non-Claims")
      |> List.last()

    assert non_claims_section =~ ~r/StoreKit adapter is not shipped/i,
           "non-claims section missing explicit StoreKit non-claim"

    assert non_claims_section =~ ~r/Play Billing adapter is not shipped/i,
           "non-claims section missing explicit Play Billing non-claim"

    assert non_claims_section =~ ~r/Device-local entitlement authority is not shipped/i,
           "non-claims section missing explicit device-local authority non-claim"

    assert non_claims_section =~ ~r/Offline purchase replay is not shipped/i,
           "non-claims section missing explicit offline purchase replay non-claim"
  end

  # -- Provider-vocabulary fence on merge-blocking surfaces --

  test "canonical support matrix commerce corridor entries stay provider-neutral" do
    # The canonical support matrix is the source of truth for merge-blocking commerce
    # claims. Its corridor entries must never carry provider-specific vocabulary —
    # any provider naming belongs in the advisory layer, not in the canonical data.
    entries = SupportMatrix.commerce_corridors()

    for entry <- entries do
      payload =
        [
          entry.corridor_role,
          entry.owner_posture,
          Enum.join(entry.prerequisites, " "),
          Enum.join(entry.denial_codes, " "),
          entry.fallback_behavior,
          inspect(entry.rebuild_requirement)
        ]
        |> Enum.join(" ")
        |> String.downcase()

      for forbidden <- @forbidden_provider_tokens do
        refute String.contains?(payload, forbidden),
               "support matrix commerce corridor #{entry.corridor_role} leaked provider token #{inspect(forbidden)}; canonical truth must stay provider-neutral"
      end
    end
  end

  test "canonical reconciliation flow subsection of guides/commerce.md stays provider-neutral" do
    # The reconciliation flow is the merge-blocking docs surface for the canonical
    # reconciliation contract. It must stay provider-neutral. The paywall walkthrough
    # below it may name explicit provider swap targets.
    content = File.read!(@guide_path)

    reconciliation_section =
      content
      |> String.split("### The Canonical Reconciliation Flow")
      |> List.last()
      |> String.split("### Paywall Corridor Walkthrough")
      |> hd()
      |> String.downcase()

    for forbidden <- @forbidden_provider_tokens do
      refute String.contains?(reconciliation_section, forbidden),
             "commerce guide canonical reconciliation flow leaked provider token #{inspect(forbidden)} — merge-blocking surfaces must stay provider-neutral"
    end
  end

  test "no provider-specific vocabulary leaks into doctor merge-blocking commerce findings", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :stale
      )

    merge_blocking_commerce_findings =
      report.findings
      |> Enum.filter(fn finding ->
        (String.starts_with?(finding.code, "commerce.") or
           finding.check in ["commerce_corridor", "commerce_summary"]) and
          Map.get(finding.details, :proof_class) in ["merge_blocking", :merge_blocking]
      end)

    assert merge_blocking_commerce_findings != [],
           "expected at least one merge-blocking commerce finding for vocabulary check"

    for finding <- merge_blocking_commerce_findings do
      payload =
        [finding.code, finding.message || "", finding.hint || "", inspect(finding.details)]
        |> Enum.join(" ")
        |> String.downcase()

      for forbidden <- @forbidden_provider_tokens do
        refute String.contains?(payload, forbidden),
               "merge-blocking commerce finding #{finding.code} leaked provider token #{inspect(forbidden)}; merge-blocking surfaces must stay provider-neutral"
      end
    end
  end

  # -- Human and JSON formatters render proof_class labels --

  test "human formatter renders proof_class labels on commerce findings", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: PurchaseCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :stale
      )

    human = Formatter.render(report)

    assert human =~ "Commerce:",
           "human formatter missing `Commerce:` section block"

    assert human =~ "snapshot_freshness:",
           "human formatter missing snapshot_freshness label inside Commerce: block"

    assert human =~ "proof_posture:",
           "human formatter missing proof_posture sub-section inside Commerce: block"

    assert human =~ "[merge-blocking]",
           "human formatter must render `[merge-blocking]` label on commerce findings"
  end

  test "json formatter renders proof_class on commerce check objects and top-level commerce_summary",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: PurchaseCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :stale
      )

    decoded = JSONFormatter.render(report) |> Jason.decode!()

    assert is_map(decoded["commerce_summary"]),
           "JSON formatter missing top-level commerce_summary key"

    assert Map.has_key?(decoded["commerce_summary"], "corridors")
    assert Map.has_key?(decoded["commerce_summary"], "proof_posture")
    assert Map.has_key?(decoded["commerce_summary"]["proof_posture"], "merge_blocking")
    assert Map.has_key?(decoded["commerce_summary"]["proof_posture"], "advisory")

    commerce_findings =
      decoded["findings"]
      |> Enum.filter(fn finding ->
        code = finding["code"] || ""
        check_name = finding["check"] || ""

        String.starts_with?(code, "commerce.") or
          check_name in ["commerce_corridor", "commerce_summary"]
      end)

    assert commerce_findings != [],
           "expected at least one commerce finding in JSON output"

    for finding <- commerce_findings do
      assert Map.has_key?(finding, "proof_class"),
             "JSON commerce finding #{inspect(finding["code"])} missing top-level proof_class key"

      assert finding["proof_class"] in ["merge_blocking", "advisory"],
             "JSON commerce finding #{inspect(finding["code"])} proof_class must be merge_blocking or advisory"
    end
  end

  # -- Hermeticity guard --

  test "phase 23 proof test stays hermetic and does not depend on example-host or provider SDK code" do
    source = File.read!(__ENV__.file) |> String.downcase()

    # The proof test must not require/import the example-host router (which is not
    # on the library compile path under `mix test`) — see deferred-items.md note on
    # example-host router compile failures in phases 5/7/8/9.
    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 23 proof test must not depend on the example-host router; keep the lane hermetic"

    # The proof test must not load example-host files via Code.require_file/2.
    # Only the support/router_fixtures.ex helper (a library-internal test fixture)
    # is permitted. We scan for the literal call form to avoid matching comments.
    require_call_lines =
      source
      |> String.split("\n")
      |> Enum.filter(&Regex.match?(~r/^\s*code\.require_file\(/, &1))

    for line <- require_call_lines do
      assert String.contains?(line, "router_fixtures.ex"),
             "phase 23 proof test loads non-fixture file via Code.require_file: #{inspect(line)}; merge-blocking lane must stay hermetic"
    end

    # The proof test must not call System.cmd, Port.open, :gen_tcp, or HTTP
    # client libraries at runtime — these are network/process escape hatches
    # that break the hermetic merge-blocking contract. We scan for actual call
    # forms (regex against parenthesized invocations or capture syntax) to
    # avoid matching the list of escape-hatch names in this very check.
    escape_hatch_call_patterns = [
      ~r/system\.cmd\s*\(/,
      ~r/port\.open\s*\(/,
      ~r/:gen_tcp\.[a-z_]+\s*\(/,
      ~r/:httpc\.[a-z_]+\s*\(/,
      ~r/req\.get\s*\(/,
      ~r/tesla\.get\s*\(/
    ]

    for pattern <- escape_hatch_call_patterns do
      refute Regex.match?(pattern, source),
             "phase 23 proof test uses non-hermetic escape-hatch call matching #{inspect(Regex.source(pattern))}; merge-blocking lane must stay hermetic"
    end
  end
end
