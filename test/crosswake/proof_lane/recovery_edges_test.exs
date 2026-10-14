defmodule Crosswake.ProofLane.RecoveryEdgesTest do
  use ExUnit.Case, async: false
  alias Crosswake.ProofLane.{Config, Generator}

  setup do
    root = Path.join(System.tmp_dir!(), "crosswake-recovery-edges-#{System.unique_integer([:positive])}")
    config = %Config{route_id: "route-0123456789abcdef", route_path: "/study/:id", indexed_db_database: "proof_lane", indexed_db_store: "mutations", mutation_id_path: "client_mutation_id", sync_path: "/study/sync", evidence_path: "/_proof/evidence", router: CrosswakeWeb.Router, ios_shell_root: Path.join(root, "native/ios")}
    on_exit(fn -> File.rm_rf!(root) end)
    assert {:ok, _} = Generator.generate(config)
    settings = Path.join(root, "native/ios/CrosswakeProofSettings.xcconfig")
    prior = File.read!(settings)
    [_header, body] = String.split(prior, "\n", parts: 2)
    body = String.replace(body, "dev.crosswake.prooflane", "org.crosswake.updated")
    digest = :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
    {:ok, root: root, config: config, settings: settings, prior: prior, desired: "// crosswake-managed-settings-sha256:#{digest}\n#{body}"}
  end

  test "proof migration refuses a host edit made after its preview", ctx do
    project = Path.join(ctx.root, "native/ios/CrosswakeProofLane.xcodeproj/project.pbxproj")
    external = File.read!(project) <> "\n// host edit after preview\n"
    assert {:error, {"PL-GENERATE-MIGRATION-CONFLICT", _}} = Generator.migrate_project_settings(ctx.config, apply: true, before_apply: fn -> File.write!(project, external) end)
    assert File.read!(project) == external
    assert File.exists?(project <> ".crosswake-migration-tmp")
  end

  test "proof migration never promotes a conflicting leftover temporary file", ctx do
    project = Path.join(ctx.root, "native/ios/CrosswakeProofLane.xcodeproj/project.pbxproj")
    before = File.read!(project)
    File.write!(project <> ".crosswake-migration-tmp", "external temporary bytes")
    assert {:error, _} = Generator.migrate_project_settings(ctx.config, apply: true)
    assert File.read!(project) == before
    assert File.read!(project <> ".crosswake-migration-tmp") == "external temporary bytes"
  end

  test "legacy recovery clears a journal only when current bytes equal its prior snapshot", ctx do
    journal(ctx, 1, true)
    assert {:ok, :recovered} = Generator.recover(ctx.config)
    assert File.read!(ctx.settings) == ctx.prior
    refute File.exists?(stage(ctx))
  end

  test "legacy recovery refuses to infer an unrecorded published generation", ctx do
    journal(ctx, 1, true)
    File.write!(ctx.settings, ctx.desired)
    assert {:error, {"PL-GENERATE-RECOVERY-LEGACY", _}} = Generator.recover(ctx.config)
    assert File.read!(ctx.settings) == ctx.desired
    assert File.exists?(stage(ctx))
    assert File.exists?(pending(ctx))
  end

  test "stage-only pre-publication crash is blocked by check and automatically recovered", ctx do
    journal(ctx, 2, false)
    assert {:error, _} = Generator.check(ctx.config)
    assert {:ok, :recovered} = Generator.recover(ctx.config)
    assert File.read!(ctx.settings) == ctx.prior
    assert {:ok, _} = Generator.generate(ctx.config)
  end

  test "stage-only post-publication crash recognizes recorded desired bytes", ctx do
    journal(ctx, 2, false)
    File.write!(ctx.settings, ctx.desired)
    assert {:ok, :recovered} = Generator.recover(ctx.config)
    assert File.read!(ctx.settings) == ctx.prior
    assert {:ok, _} = Generator.generate(ctx.config)
  end

  test "a recognized unpromoted settings temporary is removed during recovery", ctx do
    journal(ctx, 2, true)
    File.write!(next(ctx), ctx.desired)
    assert {:ok, :recovered} = Generator.recover(ctx.config)
    refute File.exists?(next(ctx))
    assert {:ok, _} = Generator.generate(ctx.config)
  end

  test "recovery preserves an externally edited unpromoted temporary and all journal evidence", ctx do
    journal(ctx, 2, true)
    File.write!(next(ctx), "external temporary bytes")
    assert {:error, {"PL-GENERATE-RECOVERY-CONFLICT", _}} = Generator.recover(ctx.config)
    assert File.read!(ctx.settings) == ctx.prior
    assert File.read!(next(ctx)) == "external temporary bytes"
    assert File.exists?(stage(ctx))
    assert File.exists?(pending(ctx))
  end

  test "recovery never promotes a conflicting leftover restore temporary", ctx do
    journal(ctx, 2, true)
    File.write!(ctx.settings, ctx.desired)
    restore = Path.join(ctx.root, "native/ios/.crosswake/ios_proof_settings.restore")
    File.write!(restore, "external restore bytes")
    assert {:error, {"PL-GENERATE-RECOVERY-CONFLICT", _}} = Generator.recover(ctx.config)
    assert File.read!(ctx.settings) == ctx.desired
    assert File.read!(restore) == "external restore bytes"
    assert File.exists?(stage(ctx))
  end

  defp journal(ctx, version, pending?) do
    File.mkdir_p!(Path.dirname(stage(ctx)))
    payload = %{"version" => version, "prior" => Base.encode64(ctx.prior)}
    payload = if version == 2, do: Map.put(payload, "desired", Base.encode64(ctx.desired)), else: payload
    File.write!(stage(ctx), Jason.encode!(payload))
    if pending?, do: File.write!(pending(ctx), "pending\n")
  end
  defp stage(ctx), do: Path.join(ctx.root, "native/ios/.crosswake/ios_proof_settings.stage.json")
  defp pending(ctx), do: Path.join(ctx.root, "native/ios/.crosswake/ios_proof_settings.pending")
  defp next(ctx), do: Path.join(ctx.root, "native/ios/.crosswake/ios_proof_settings.next")
end
