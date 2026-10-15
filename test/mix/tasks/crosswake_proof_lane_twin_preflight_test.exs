defmodule Mix.Tasks.Crosswake.ProofLane.TwinPreflightTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{TwinGitFixtures, TwinPreflight, TwinProducers, TwinReceipt}
  alias Mix.Tasks.Crosswake.ProofLane.TwinPreflight, as: Task

  @report "report: none written; no run root was created or consumed"
  @allowed_action "Source and run root pass and the origin port is free at this moment; the backend build and the live journey are checked only by the real run."
  @mismatch_action "The prepared record's resource or fixture digests do not match the identity file and candidate; write a new prepared record and run the preflight again"
  @artifacts ["receipt.json", "expectations.json", "twin-result.json"]

  setup do
    TwinGitFixtures.env_restore("TMPDIR")
    TwinGitFixtures.env_restore("DATABASE_PATH")
    System.delete_env("DATABASE_PATH")

    fx = TwinGitFixtures.repo!()
    side = fx.side
    root = Path.join(side, "run")
    File.mkdir!(root)
    File.chmod!(root, 0o700)
    sandbox = Path.join(side, "sandbox")
    File.mkdir!(sandbox)
    File.chmod!(sandbox, 0o700)
    System.put_env("TMPDIR", sandbox)

    host = Path.join(fx.dir, "examples/phoenix_host")
    fixtures = Path.join(host, "native/ios/crosswake_shell/Fixtures")

    digest = fn path ->
      {:ok, d} = TwinProducers.file_digest(path)
      d
    end

    media =
      digest.(
        Path.join(
          host,
          "native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff"
        )
      )

    resources = [
      digest.(Path.join(fixtures, "crosswake_manifest.json")),
      digest.(Path.join(fixtures, "route_activation.json")),
      digest.(Path.join(host, "priv/static/offline_study.js"))
    ]

    ctx = %{
      fx: fx,
      dir: fx.dir,
      root: root,
      sandbox: sandbox,
      identity: fx.identity.(%{}),
      resources: resources,
      media: media,
      port: free_port()
    }

    Map.put(ctx, :record, record(ctx, %{}))
  end

  defp free_port do
    {:ok, l} = :gen_tcp.listen(0, ip: {127, 0, 0, 1}, reuseaddr: false)
    {:ok, port} = :inet.port(l)
    :gen_tcp.close(l)
    port
  end

  defp record(ctx, overrides, mode \\ 0o600) do
    path = Path.join(ctx.fx.side, "record-#{System.unique_integer([:positive])}.json")

    body =
      Map.merge(
        %{
          candidate_path: ctx.dir,
          expected_head: ctx.fx.head,
          expected_tree: ctx.fx.tree,
          origin: "http://127.0.0.1:#{ctx.port}",
          resource_digests: ctx.resources,
          fixture_digests: [ctx.media]
        },
        overrides
      )

    File.write!(path, Jason.encode!(body))
    File.chmod!(path, mode)
    path
  end

  defp args(ctx, rec \\ nil, root \\ :default) do
    root_args = if root == :default, do: ["--run-root", ctx.root], else: root
    ["ios", "--candidate", rec || ctx.record] ++ root_args ++ ["--identity", ctx.identity]
  end

  defp tree_listing(root) do
    entries =
      root
      |> Path.join("**")
      |> Path.wildcard(match_dot: true)
      |> Enum.map(fn path ->
        {:ok, st} = File.lstat(path, time: :posix)
        {Path.relative_to(path, root), st.type, st.size, st.mode, st.mtime}
      end)

    Enum.sort(entries)
  end

  defp snapshot(ctx) do
    %{
      root: tree_listing(ctx.root),
      candidate: tree_listing(ctx.dir),
      git: tree_listing(Path.join(ctx.dir, ".git")),
      sandbox: tree_listing(ctx.sandbox)
    }
  end

  defp unchanged!(ctx, before_snapshot) do
    assert snapshot(ctx) == before_snapshot

    for name <- @artifacts do
      refute File.exists?(Path.join(ctx.root, name))
    end
  end

  test "an allowed preflight prints four exact lines, exits 0 and changes nothing", ctx do
    before_snapshot = snapshot(ctx)

    assert {0,
            [
              "result: allowed",
              "first cause: none",
              @report,
              "next action: " <> @allowed_action
            ]} == Task.execute(args(ctx), [])

    unchanged!(ctx, before_snapshot)
    {:ok, l} = :gen_tcp.listen(ctx.port, ip: {127, 0, 0, 1}, reuseaddr: false)
    :gen_tcp.close(l)
  end

  defp blocked!(ctx, run_args) do
    before_snapshot = snapshot(ctx)
    result = Task.execute(run_args, [])
    unchanged!(ctx, before_snapshot)
    result
  end

  defp assert_blocked({status, lines}, cause) do
    assert status == 2
    assert length(lines) == 4
    assert Enum.at(lines, 0) == "result: blocked"
    assert Enum.at(lines, 1) == "first cause: " <> Atom.to_string(cause)
    assert Enum.at(lines, 2) == @report
    lines
  end

  test "a dirty candidate is blocked and nothing changes", ctx do
    File.write!(Path.join(ctx.dir, "stray.txt"), "x")
    before_snapshot = snapshot(ctx)

    assert {2,
            [
              "result: blocked",
              "first cause: source_dirty",
              @report,
              "next action: The candidate has 1 changed or untracked file. Commit or remove the changes, then write a new prepared record and run into a new run root."
            ]} == Task.execute(args(ctx), [])

    unchanged!(ctx, before_snapshot)
  end

  test "a reused run root is blocked and nothing changes", ctx do
    receipt = Path.join(ctx.root, "receipt.json")
    File.write!(receipt, "{\"kept\":true}")
    bytes = File.read!(receipt)
    before_snapshot = snapshot(ctx)

    lines = assert_blocked(Task.execute(args(ctx), []), :run_root_reused)
    assert length(lines) == 4

    assert snapshot(ctx) == before_snapshot
    assert File.read!(receipt) == bytes
    refute File.exists?(Path.join(ctx.root, "expectations.json"))
    refute File.exists?(Path.join(ctx.root, "twin-result.json"))
  end

  test "a missing run root is blocked and nothing changes", ctx do
    lines = assert_blocked(blocked!(ctx, args(ctx, nil, [])), :prerequisite_missing)
    assert Enum.at(lines, 3) == "next action: Name the private run root you plan to use"
    assert tree_listing(ctx.sandbox) == []
  end

  test "a bad candidate record is blocked and nothing changes", ctx do
    loose = record(ctx, %{}, 0o644)
    assert_blocked(blocked!(ctx, args(ctx, loose)), :prerequisite_missing)

    garbage = Path.join(ctx.fx.side, "garbage-record.json")
    File.write!(garbage, "not json")
    File.chmod!(garbage, 0o600)
    assert_blocked(blocked!(ctx, args(ctx, garbage)), :prerequisite_missing)
  end

  test "bad options and an unreadable identity exit 2 without raising", ctx do
    missing_identity = Path.join(ctx.fx.side, "no-such-identity.json")
    unreadable = Path.join(ctx.fx.side, "garbage-identity.json")
    File.write!(unreadable, "not json")

    cases = [
      {["android"], :prerequisite_missing},
      {["ios", "--unknown-flag"], :prerequisite_missing},
      {[], :prerequisite_missing},
      {["ios", "--candidate", ctx.record, "--run-root", ctx.root], :identity_unknown},
      {["ios", "--candidate", ctx.record, "--run-root", ctx.root, "--identity", missing_identity],
       :identity_unknown},
      {["ios", "--candidate", ctx.record, "--run-root", ctx.root, "--identity", unreadable],
       :identity_unknown}
    ]

    for {run_args, cause} <- cases do
      {status, lines} = Task.execute(run_args, [])
      assert status == 2
      assert length(lines) == 4
      assert hd(lines) == "result: blocked"
      assert Enum.at(lines, 1) == "first cause: " <> Atom.to_string(cause)
    end
  end

  test "an identity that does not match the record digests is blocked", ctx do
    [first | rest] = ctx.resources
    changed = record(ctx, %{resource_digests: [String.duplicate("0", 64) | rest]})
    lines = assert_blocked(blocked!(ctx, args(ctx, changed)), :identity_mismatch)
    assert Enum.at(lines, 3) == "next action: " <> @mismatch_action
    assert first != String.duplicate("0", 64)

    empty_fixtures = record(ctx, %{fixture_digests: []})
    lines = assert_blocked(blocked!(ctx, args(ctx, empty_fixtures)), :identity_mismatch)
    assert Enum.at(lines, 3) == "next action: " <> @mismatch_action
  end

  test "a head that does not match the record is blocked", ctx do
    other = record(ctx, %{expected_head: String.duplicate("a", 40)})
    assert_blocked(blocked!(ctx, args(ctx, other)), :identity_mismatch)
  end

  test "a configuration that can hide changes is blocked", ctx do
    TwinGitFixtures.set_config!(ctx.dir, "filter.x.clean", "cat")
    lines = assert_blocked(blocked!(ctx, args(ctx)), :source_dirty)
    assert Enum.at(lines, 3) =~ "git configuration can hide changes"
  end

  test "an occupied origin port is blocked", ctx do
    {:ok, listener} = :gen_tcp.listen(ctx.port, ip: {127, 0, 0, 1}, reuseaddr: false)

    try do
      assert_blocked(blocked!(ctx, args(ctx)), :origin_port_occupied)
    after
      :gen_tcp.close(listener)
    end
  end

  test "a run root owned by another user is blocked", ctx do
    {out, 0} = System.cmd("id", ["-u"])
    uid = out |> String.trim() |> String.to_integer()

    assert {:blocked, :prerequisite_missing, action} =
             TwinPreflight.check(
               candidate: ctx.record,
               run_root: ctx.root,
               identity: ctx.identity,
               current_uid: uid + 1
             )

    assert is_binary(action)
  end

  test "an empty check list is blocked", ctx do
    assert {:blocked, :prerequisite_missing,
            "No preflight checks were configured; nothing was checked."} ==
             TwinPreflight.check(
               checks: [],
               candidate: ctx.record,
               run_root: ctx.root,
               identity: ctx.identity
             )
  end

  test "no preflight output carries the candidate path or home directory", ctx do
    File.write!(Path.join(ctx.dir, "stray.txt"), "x")
    receipt_root = Path.join(ctx.fx.side, "run2")
    File.mkdir!(receipt_root)
    File.chmod!(receipt_root, 0o700)
    File.write!(Path.join(receipt_root, "receipt.json"), "{}")

    runs = [
      args(ctx),
      args(ctx, nil, ["--run-root", receipt_root]),
      args(ctx, nil, []),
      args(ctx, record(ctx, %{}, 0o644)),
      ["android"],
      ["ios", "--candidate", ctx.record, "--run-root", ctx.root]
    ]

    causes = Enum.map(TwinReceipt.causes(), &("first cause: " <> Atom.to_string(&1)))
    home = System.user_home!()

    for run_args <- runs do
      {status, lines} = Task.execute(run_args, [])
      assert status == 2
      assert length(lines) == 4

      for line <- lines do
        refute line =~ ctx.dir
        refute line =~ ctx.fx.side
        refute line =~ home
      end

      assert Enum.at(lines, 1) in causes
    end
  end

  test "the preflight never calls the effectful run path", _ctx do
    sources = [
      File.read!("lib/crosswake/proof_lane/twin_preflight.ex"),
      File.read!("lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex")
    ]

    forbidden = [
      "TwinRuntime.prepare",
      "TwinRuntime.commit",
      "TwinProducers.freeze",
      "write_expectations",
      "write_and_verify",
      "blocked_receipt",
      "File.write",
      "File.mkdir",
      "go/no-go"
    ]

    for source <- sources, name <- forbidden do
      refute source =~ name
    end
  end
end
