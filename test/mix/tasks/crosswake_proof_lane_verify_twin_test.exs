defmodule Mix.Tasks.Crosswake.ProofLane.VerifyTwinTest do
  use ExUnit.Case, async: false

  import Bitwise

  alias Crosswake.ProofLane.{TwinReceipt, TwinRuntime}
  alias Mix.Tasks.Crosswake.ProofLane.VerifyTwin

  @head String.duplicate("a", 40)
  @tree String.duplicate("b", 40)

  setup do
    base =
      Path.join(
        System.tmp_dir!(),
        "twin-test-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)
      )

    File.mkdir_p!(base)
    File.chmod!(base, 0o700)
    on_exit(fn -> File.rm_rf(base) end)

    candidate = Path.join(base, "candidate")
    File.mkdir_p!(candidate)
    File.write!(Path.join(candidate, "mix.lock"), "%{}\n")
    File.mkdir_p!(Path.join(candidate, "examples/phoenix_host"))
    File.write!(Path.join(candidate, "examples/phoenix_host/mix.lock"), "%{}\n")
    run_root = Path.join(base, "run")
    File.mkdir!(run_root)
    File.chmod!(run_root, 0o700)
    {:ok, base: base, candidate: candidate, run_root: run_root}
  end

  # The pre-journey default: no producers, so every observation is missing.
  def empty_producers(_runtime, _expectations), do: {:ok, %{}, []}

  defp free_port do
    {:ok, l} = :gen_tcp.listen(0, ip: {127, 0, 0, 1}, reuseaddr: false)
    {:ok, port} = :inet.port(l)
    :gen_tcp.close(l)
    port
  end

  defp record(ctx, port \\ nil, mode \\ 0o600) do
    path = Path.join(ctx.base, "candidate-record-#{System.unique_integer([:positive])}.json")

    File.write!(
      path,
      Jason.encode!(%{
        candidate_path: ctx.candidate,
        expected_head: @head,
        expected_tree: @tree,
        origin: "http://127.0.0.1:#{port || free_port()}",
        resource_digests: [String.duplicate("d", 64)],
        fixture_digests: [String.duplicate("e", 64)]
      })
    )

    File.chmod!(path, mode)
    path
  end

  defp args(ctx, record), do: ["ios", "--candidate", record, "--run-root", ctx.run_root]

  defp full_producers(overrides \\ %{}) do
    fn runtime, expectations ->
      observations =
        for %{sub_observations: subs} <- TwinReceipt.roster(),
            %{id: id, owner: owner} <- subs,
            id != "TW-T10-02" do
          attrs =
            Map.merge(
              %{
                id: id,
                owner: owner,
                run_id: runtime.run_id,
                outcome: :passed,
                measure: nil,
                cause: nil
              },
              Map.get(overrides, id, %{})
            )

          {:ok, o} = TwinReceipt.observation(attrs)
          o
        end

      {:ok, expectations.joins, observations}
    end
  end

  test "unknown switches and extra positionals raise before creating any file", ctx do
    before = File.ls!(ctx.base) |> Enum.sort()

    for bad <- [["ios", "--bogus"], ["ios", "extra"], ["android"], [], ["ios", "--candidate"]] do
      assert_raise Mix.Error, "verify_twin.invalid_options", fn -> VerifyTwin.execute(bad, []) end
    end

    assert File.ls!(ctx.base) |> Enum.sort() == before
    assert File.ls!(ctx.run_root) == []
  end

  test "missing or non-private run root or candidate exits 2 with prerequisite_missing", ctx do
    rec = record(ctx)

    assert {2, [_, "first cause: prerequisite_missing", "report: none written", _]} =
             VerifyTwin.execute(
               ["ios", "--candidate", rec, "--run-root", Path.join(ctx.base, "absent")],
               producers: &empty_producers/2
             )

    File.chmod!(ctx.run_root, 0o755)

    assert {2, [_, "first cause: prerequisite_missing" | _]} =
             VerifyTwin.execute(args(ctx, rec), producers: &empty_producers/2)

    File.chmod!(ctx.run_root, 0o700)

    loose = record(ctx, nil, 0o644)

    assert {2, [_, "first cause: prerequisite_missing" | _]} =
             VerifyTwin.execute(args(ctx, loose), producers: &empty_producers/2)

    assert {2, [_, "first cause: prerequisite_missing" | _]} =
             VerifyTwin.execute(["ios", "--run-root", ctx.run_root],
               producers: &empty_producers/2
             )

    assert File.ls!(ctx.run_root) == []
  end

  test "an occupied origin port exits 2 with a concrete action and leaves the occupant alone",
       ctx do
    {:ok, occupant} =
      :gen_tcp.listen(0, [:binary, ip: {127, 0, 0, 1}, reuseaddr: false, active: false])

    {:ok, port} = :inet.port(occupant)
    rec = record(ctx, port)

    assert {2, [_, "first cause: origin_port_occupied", _, action]} =
             VerifyTwin.execute(args(ctx, rec), producers: &empty_producers/2)

    assert action ==
             "next action: Free 127.0.0.1:#{port} (another process is listening on it), then run again with a new run root"

    # The occupant is untouched and still accepts connections.
    assert {:ok, client} = :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false], 1_000)
    :gen_tcp.close(client)
    assert {:ok, _} = :inet.port(occupant)
    :gen_tcp.close(occupant)
    assert File.ls!(ctx.run_root) == []
  end

  test "the origin stays held between prepare and stop_all", ctx do
    port = free_port()
    rec = record(ctx, port)
    assert {:ok, runtime} = TwinRuntime.prepare(candidate: rec, run_root: ctx.run_root)

    assert {:error, :eaddrinuse} =
             :gen_tcp.listen(port, ip: {127, 0, 0, 1}, reuseaddr: false, active: false)

    assert :ok = TwinRuntime.stop_all(runtime)

    assert {:ok, again} =
             :gen_tcp.listen(port, ip: {127, 0, 0, 1}, reuseaddr: false, active: false)

    :gen_tcp.close(again)
    assert (File.stat!(ctx.run_root).mode &&& 0o077) == 0
  end

  test "a run root that already holds a receipt is refused and left unchanged", ctx do
    receipt = Path.join(ctx.run_root, "receipt.json")
    File.write!(receipt, "first result")
    parent = self()
    producers = fn _rt, _exp -> send(parent, :producers_called) && {:ok, %{}, []} end

    assert {2, [_, "first cause: run_root_reused", "report: none written", _]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: producers)

    refute_received :producers_called
    assert File.read!(receipt) == "first result"
  end

  test "a database path outside the run root or already present exits 2 before migration", ctx do
    rec = record(ctx)
    outside = Path.join(ctx.base, "elsewhere.sqlite3")

    assert {:error, %{cause: :database_path_rejected}} =
             TwinRuntime.prepare(candidate: rec, run_root: ctx.run_root, database_path: outside)

    existing = Path.join(ctx.run_root, "taken.sqlite3")
    File.write!(existing, "")

    assert {:error, %{cause: :database_path_rejected}} =
             TwinRuntime.prepare(candidate: rec, run_root: ctx.run_root, database_path: existing)

    traversal = Path.join([ctx.run_root, "..", "escape.sqlite3"])

    assert {:error, %{cause: :database_path_rejected}} =
             TwinRuntime.prepare(candidate: rec, run_root: ctx.run_root, database_path: traversal)

    previous = System.get_env("DATABASE_PATH")
    System.put_env("DATABASE_PATH", outside)

    try do
      assert {2, [_, "first cause: database_path_rejected" | _]} =
               VerifyTwin.execute(args(ctx, rec), producers: &empty_producers/2)
    after
      if previous,
        do: System.put_env("DATABASE_PATH", previous),
        else: System.delete_env("DATABASE_PATH")
    end

    assert {:ok, runtime} = TwinRuntime.prepare(candidate: rec, run_root: ctx.run_root)
    assert String.starts_with?(runtime.database_path, ctx.run_root <> "/")
    refute File.exists?(runtime.database_path)
    TwinRuntime.stop_all(runtime)
  end

  test "a child past its deadline is terminated and reaped and the first failure is kept", ctx do
    {:ok, runtime} = TwinRuntime.prepare(candidate: record(ctx), run_root: ctx.run_root)
    sleep = System.find_executable("sleep")

    {:ok, child} =
      TwinRuntime.start_child(runtime, :slow, %{path: sleep, args: ["30"], deadline_ms: 100})

    assert TwinRuntime.alive?(child.os_pid)

    assert {:error, :child_timeout} = TwinRuntime.await_exit(runtime, child)
    refute TwinRuntime.alive?(child.os_pid)
    assert TwinRuntime.first_failure(runtime) == :child_timeout

    TwinRuntime.record_failure(runtime, :host_denied)
    assert TwinRuntime.first_failure(runtime) == :child_timeout

    {:ok, quick} =
      TwinRuntime.start_child(runtime, :quick, %{path: System.find_executable("true"), args: []})

    assert {:ok, 0} = TwinRuntime.await_exit(runtime, quick)
    assert :ok = TwinRuntime.stop_all(runtime)
  end

  test "stop_all terminates and reaps a still-running tracked child by its own handle", ctx do
    {:ok, runtime} = TwinRuntime.prepare(candidate: record(ctx), run_root: ctx.run_root)
    sleep = System.find_executable("sleep")
    {:ok, a} = TwinRuntime.start_child(runtime, :a, %{path: sleep, args: ["30"]})
    {:ok, b} = TwinRuntime.start_child(runtime, :b, %{path: sleep, args: ["30"]})
    assert TwinRuntime.alive?(a.os_pid) and TwinRuntime.alive?(b.os_pid)

    assert :ok = TwinRuntime.stop_all(runtime)
    refute TwinRuntime.alive?(a.os_pid)
    refute TwinRuntime.alive?(b.os_pid)
  end

  test "backend environment is closed and flag names are gated", ctx do
    {:ok, runtime} = TwinRuntime.prepare(candidate: record(ctx), run_root: ctx.run_root)

    env =
      TwinRuntime.env_for_backend(runtime, 4801, [
        {"CROSSWAKE_TWIN_FLAG", "on"},
        {"SECRET_TOKEN", "x"},
        {"HOME", "/"}
      ])

    assert {"MIX_ENV", "test"} in env
    assert {"PORT", "4801"} in env
    assert {"DATABASE_PATH", runtime.database_path} in env
    assert {"PHX_SERVER", "true"} in env
    assert {"CROSSWAKE_TWIN_FLAG", "on"} in env
    refute Enum.empty?(env)
    refute Enum.any?(env, fn {k, _} -> k in ["SECRET_TOKEN", "HOME"] end)
    TwinRuntime.stop_all(runtime)
  end

  test "exit_status_for maps passed 0, failed 1, blocked 2 and unknown rule ids to 2" do
    assert VerifyTwin.exit_status_for(:passed) == 0
    assert VerifyTwin.exit_status_for(:failed) == 1
    assert VerifyTwin.exit_status_for(:blocked) == 2
    assert VerifyTwin.exit_status_for("TW-NEVER-SEEN") == 2
    assert VerifyTwin.exit_status_for(:surprise) == 2
  end

  test "a completed passing run writes private receipt and projection and prints four lines",
       ctx do
    assert {0, lines} = VerifyTwin.execute(args(ctx, record(ctx)), producers: full_producers())

    assert [
             "result: passed (exit 0)",
             "first cause: none",
             "report: " <> report,
             "next action: " <> _
           ] = lines

    assert report == Path.join(ctx.run_root, "receipt.json")
    assert length(lines) == 4
    refute Enum.any?(lines, &(&1 =~ "127.0.0.1"))

    for name <- ["receipt.json", "twin-result.json"] do
      assert (File.stat!(Path.join(ctx.run_root, name)).mode &&& 0o777) == 0o600
    end

    bytes = File.read!(report)
    assert {:ok, receipt} = TwinReceipt.decode(bytes)
    projection = ctx.run_root |> Path.join("twin-result.json") |> File.read!() |> Jason.decode!()
    assert projection["exit_status"] == 0
    assert projection["overall_status"] == "passed"

    assert projection["receipt_sha256"] ==
             :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

    assert {:ok, expected} = TwinReceipt.project(receipt, 0)
    assert projection == Jason.decode!(Jason.encode!(expected))
    assert File.ls!(ctx.run_root) |> Enum.sort() == ["receipt.json", "twin-result.json"]

    # A second run on the same root is refused and keeps the first result.
    assert {2, [_, "first cause: run_root_reused" | _]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: full_producers())

    assert File.read!(report) == bytes
  end

  test "a registry gone before the command's stop_all reaches the printed verdict, not the receipt",
       ctx do
    gone = fn runtime, expectations ->
      :ok = Agent.stop(runtime.registry)
      full_producers().(runtime, expectations)
    end

    assert {0, lines} = VerifyTwin.execute(args(ctx, record(ctx)), producers: gone)

    assert [
             "result: passed (exit 0)",
             "first cause: registry_gone",
             "report: " <> report,
             "next action: " <> next
           ] = lines

    assert next =~ "registry"
    assert report == Path.join(ctx.run_root, "receipt.json")
    assert {:ok, _receipt} = report |> File.read!() |> TwinReceipt.decode()
    refute File.read!(report) =~ "registry_gone"
    refute File.read!(Path.join(ctx.run_root, "twin-result.json")) =~ "registry_gone"
  end

  test "the real journey path requires --identity", ctx do
    assert_raise Mix.Error, "verify_twin.identity_required", fn ->
      VerifyTwin.execute(args(ctx, record(ctx)), [])
    end
  end

  test "a preflight block on the real journey path still writes a receipt with every id blocked",
       ctx do
    identity = Path.join(ctx.base, "absent-identity.json")

    assert {2, [_, "first cause: identity_unknown", report, _]} =
             VerifyTwin.execute(args(ctx, record(ctx)) ++ ["--identity", identity], [])

    assert report == "report: " <> Path.join(ctx.run_root, "receipt.json")
    {:ok, receipt} = TwinReceipt.decode(File.read!(Path.join(ctx.run_root, "receipt.json")))
    assert receipt.overall_status == :blocked
    assert length(Enum.flat_map(receipt.groups, & &1.sub_observations)) == 49

    assert Enum.all?(
             Enum.flat_map(receipt.groups, & &1.sub_observations),
             &(&1.outcome == :blocked)
           )

    assert File.exists?(Path.join(ctx.run_root, "twin-result.json"))
  end

  test "observed failure exits 1, missing observation exits 2, both write a receipt", ctx do
    failing =
      full_producers(%{"TW-T05-04" => %{outcome: :failed, cause: :contradiction_observed}})

    assert {1, [_, "first cause: TW-T05-04 contradiction_observed", _, _]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: failing)

    assert File.exists?(Path.join(ctx.run_root, "receipt.json"))

    other = Path.join(ctx.base, "run2")
    File.mkdir!(other)
    File.chmod!(other, 0o700)

    assert {2, [_, "first cause: TW-T01-01 observation_missing", _, _]} =
             VerifyTwin.execute(["ios", "--candidate", record(ctx), "--run-root", other],
               producers: &empty_producers/2
             )

    {:ok, receipt} = TwinReceipt.decode(File.read!(Path.join(other, "receipt.json")))
    assert receipt.overall_status == :blocked
  end

  test "a producer that hits a child deadline preserves child_timeout as the first cause", ctx do
    producers = fn runtime, expectations ->
      {:ok, child} =
        TwinRuntime.start_child(runtime, :slow, %{
          path: System.find_executable("sleep"),
          args: ["30"],
          deadline_ms: 100
        })

      {:error, :child_timeout} = TwinRuntime.await_exit(runtime, child)

      {:ok, observed, observations} =
        full_producers(%{"TW-T02-04" => %{outcome: :blocked, cause: :child_timeout}}).(
          runtime,
          expectations
        )

      send(self(), {:pid, child.os_pid})
      {:ok, observed, observations}
    end

    assert {2, [_, "first cause: TW-T02-04 child_timeout" | _]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: producers)

    assert_received {:pid, os_pid}
    refute TwinRuntime.alive?(os_pid)
  end

  test "a journey that released its children and then blocks still writes its receipt and exits 2",
       ctx do
    producers = fn runtime, _expectations ->
      :ok = TwinRuntime.stop_children(runtime)
      {:blocked, :attachment_check_unavailable}
    end

    assert {2, [_, "first cause: attachment_check_unavailable", report, _]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: producers)

    assert report == "report: " <> Path.join(ctx.run_root, "receipt.json")
    {:ok, receipt} = TwinReceipt.decode(File.read!(Path.join(ctx.run_root, "receipt.json")))
    assert receipt.overall_status == :blocked
  end

  test "a dirty candidate surfaces source_dirty as the first cause and exits 2", ctx do
    producers = fn runtime, _expectations ->
      :ok = TwinRuntime.stop_children(runtime)
      {:blocked, :source_dirty}
    end

    assert {2, [_, "first cause: source_dirty", report, _]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: producers)

    assert report == "report: " <> Path.join(ctx.run_root, "receipt.json")
    {:ok, receipt} = TwinReceipt.decode(File.read!(Path.join(ctx.run_root, "receipt.json")))
    assert receipt.overall_status == :blocked
  end

  test "a registry already released before the receipt never crashes the command", ctx do
    blocked = fn runtime, _expectations ->
      :ok = TwinRuntime.stop_all(runtime)
      {:blocked, :attachment_check_unavailable}
    end

    assert {2, [_, "first cause: attachment_check_unavailable", _, _]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: blocked)

    other = Path.join(ctx.base, "run-released")
    File.mkdir!(other)
    File.chmod!(other, 0o700)

    passing = fn runtime, expectations ->
      :ok = TwinRuntime.stop_all(runtime)
      full_producers().(runtime, expectations)
    end

    assert {0, ["result: passed (exit 0)", "first cause: registry_gone" | _]} =
             VerifyTwin.execute(["ios", "--candidate", record(ctx), "--run-root", other],
               producers: passing
             )
  end

  test "producer results and public strings stay closed", ctx do
    bad = fn _rt, _exp -> :nonsense end

    assert {2, [_, "first cause: TW-PRODUCERS-RESULT", "report: none written", _]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: bad)

    stale = fn runtime, expectations ->
      {:ok, o} =
        TwinReceipt.observation(%{
          id: "TW-T01-01",
          owner: :host_adapter,
          run_id: "twin-0000000000000000",
          outcome: :passed,
          measure: nil,
          cause: nil
        })

      {:ok, expectations.joins, [o | elem(full_producers().(runtime, expectations), 2)]}
    end

    other = Path.join(ctx.base, "run3")
    File.mkdir!(other)
    File.chmod!(other, 0o700)

    assert {2, [_, "first cause: TW-OBS-STALE", "report: none written", _]} =
             VerifyTwin.execute(["ios", "--candidate", record(ctx), "--run-root", other],
               producers: stale
             )

    source = File.read!("lib/mix/tasks/crosswake.proof_lane.verify_twin.ex")
    refute source =~ "gen.shell"
    refute source =~ "B2C"
    refute File.read!("lib/crosswake/proof_lane/twin_runtime.ex") =~ "B2C"
  end

  test "a run root inside the candidate, or aliased into it, is refused; a prefix sibling is not",
       ctx do
    rec = record(ctx)

    inside = Path.join(ctx.candidate, "run")
    File.mkdir_p!(inside)
    File.chmod!(inside, 0o700)

    assert {2, [_, "first cause: prerequisite_missing", "report: none written", _]} =
             VerifyTwin.execute(
               ["ios", "--candidate", rec, "--run-root", inside],
               producers: &empty_producers/2
             )

    refute File.exists?(Path.join(inside, "receipt.json"))

    alias_path = Path.join(ctx.base, "alias")
    File.ln_s!(ctx.candidate, alias_path)
    aliased = Path.join(alias_path, "run")

    assert {2, [_, "first cause: prerequisite_missing", "report: none written", _]} =
             VerifyTwin.execute(
               ["ios", "--candidate", rec, "--run-root", aliased],
               producers: &empty_producers/2
             )

    refute File.exists?(Path.join(inside, "receipt.json"))

    sibling = ctx.candidate <> "-run"
    File.mkdir_p!(sibling)
    File.chmod!(sibling, 0o700)

    assert {0, _} =
             VerifyTwin.execute(
               ["ios", "--candidate", rec, "--run-root", sibling],
               producers: full_producers()
             )
  end

  describe "the freeze needs both lockfiles" do
    test "a candidate missing examples/phoenix_host/mix.lock blocks the freeze with identity_unknown",
         ctx do
      File.rm!(Path.join(ctx.candidate, "examples/phoenix_host/mix.lock"))

      assert {2, [_, "first cause: identity_unknown", report, _]} =
               VerifyTwin.execute(args(ctx, record(ctx)), producers: full_producers())

      assert report == "report: " <> Path.join(ctx.run_root, "receipt.json")
      assert File.regular?(Path.join(ctx.run_root, "receipt.json"))
    end

    test "a candidate missing the root mix.lock blocks the freeze with identity_unknown", ctx do
      File.rm!(Path.join(ctx.candidate, "mix.lock"))

      assert {2, [_, "first cause: identity_unknown", report, _]} =
               VerifyTwin.execute(args(ctx, record(ctx)), producers: full_producers())

      assert report == "report: " <> Path.join(ctx.run_root, "receipt.json")
      assert File.regular?(Path.join(ctx.run_root, "receipt.json"))
    end

    test "an unreadable lockfile blocks the freeze with identity_unknown", ctx do
      lock = Path.join(ctx.candidate, "examples/phoenix_host/mix.lock")

      # Root can read any file, so a mode 000 file would not be unreadable.
      if System.cmd("id", ["-u"]) |> elem(0) |> String.trim() == "0" do
        :ok
      else
        File.chmod!(lock, 0o000)
        on_exit(fn -> File.chmod(lock, 0o600) end)

        assert {2, [_, "first cause: identity_unknown", report, _]} =
                 VerifyTwin.execute(args(ctx, record(ctx)), producers: full_producers())

        assert report == "report: " <> Path.join(ctx.run_root, "receipt.json")
        assert File.regular?(Path.join(ctx.run_root, "receipt.json"))
      end
    end
  end

  defp git_in(dir, args) do
    home = dir <> "-home"
    File.mkdir_p!(home)

    {_, 0} =
      System.cmd(
        "git",
        [
          "-c",
          "user.name=t",
          "-c",
          "user.email=t@example.test",
          "-c",
          "commit.gpgsign=false" | args
        ],
        cd: dir,
        stderr_to_stdout: true,
        env: [{"HOME", home}, {"GIT_CONFIG_GLOBAL", "/dev/null"}, {"GIT_CONFIG_NOSYSTEM", "1"}]
      )

    :ok
  end

  defp dirty_producers do
    fn runtime, _expectations ->
      :ok = TwinRuntime.stop_children(runtime)
      {:blocked, :source_dirty}
    end
  end

  defp blocked_pairs(ctx) do
    {:ok, receipt} = TwinReceipt.decode(File.read!(Path.join(ctx.run_root, "receipt.json")))

    for group <- receipt.groups,
        o <- group.sub_observations,
        o.id != "TW-T10-02",
        do: {o.measure, o.cause}
  end

  test "a dirty git candidate reports the typed count in plain language and leaks no path", ctx do
    git_in(ctx.candidate, ["init", "-q"])
    git_in(ctx.candidate, ["add", "mix.lock", "examples/phoenix_host/mix.lock"])
    git_in(ctx.candidate, ["commit", "-q", "-m", "fixture"])
    marker = "zz-leak-marker-" <> Base.encode16(:crypto.strong_rand_bytes(4), case: :lower)
    File.write!(Path.join(ctx.candidate, marker), "x")

    {code, lines} = VerifyTwin.execute(args(ctx, record(ctx)), producers: dirty_producers())

    assert code == 2

    assert lines == [
             "result: blocked (exit 2)",
             "first cause: source_dirty",
             "report: " <> Path.join(ctx.run_root, "receipt.json"),
             "next action: The candidate has 1 changed or untracked file. Commit or remove the changes, then write a new prepared record and run into a new run root."
           ]

    assert blocked_pairs(ctx) |> Enum.uniq() == [{1, :source_dirty}]

    # Floor on lines, not on the iterated list: the loop below iterates lines plus two
    # File.read! texts, so it is never empty. What can shrink silently is lines; fewer
    # printed lines would make the refutes check fewer of the places a leak can appear.
    assert length(lines) == 4

    for text <-
          lines ++
            [
              File.read!(Path.join(ctx.run_root, "receipt.json")),
              File.read!(Path.join(ctx.run_root, "twin-result.json"))
            ] do
      refute text =~ marker
    end
  end

  test "a candidate that is not a git repository reports no count", ctx do
    assert {2, [_, "first cause: source_dirty", _, action]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: dirty_producers())

    assert action ==
             "next action: " <>
               Crosswake.ProofLane.TwinProducers.source_block_action(:unavailable)

    refute action =~ ~r/\d/
    assert blocked_pairs(ctx) |> Enum.uniq() == [{nil, :source_dirty}]
  end

  test "a flag-hidden edit reports separate counts and measure two", ctx do
    git_in(ctx.candidate, ["init", "-q"])
    git_in(ctx.candidate, ["add", "mix.lock", "examples/phoenix_host/mix.lock"])
    git_in(ctx.candidate, ["commit", "-q", "-m", "fixture"])
    git_in(ctx.candidate, ["update-index", "--assume-unchanged", "mix.lock"])
    File.write!(Path.join(ctx.candidate, "mix.lock"), "%{changed: true}\n")

    assert {2, [_, "first cause: source_dirty", _, action]} =
             VerifyTwin.execute(args(ctx, record(ctx)), producers: dirty_producers())

    assert action ==
             "next action: " <>
               Crosswake.ProofLane.TwinProducers.source_block_action(
                 {:ok, %{modified: 1, flagged: 1, excludes: 0}}
               )

    assert action =~ "1 changed or untracked file; and 1 tracked file marked unchanged"
    assert blocked_pairs(ctx) |> Enum.uniq() == [{2, :source_dirty}]
  end

  test "no source_dirty output carries the candidate path or home directory", ctx do
    git_in(ctx.candidate, ["init", "-q"])
    git_in(ctx.candidate, ["add", "mix.lock", "examples/phoenix_host/mix.lock"])
    git_in(ctx.candidate, ["commit", "-q", "-m", "fixture"])
    marker = "zz-leak-marker-" <> Base.encode16(:crypto.strong_rand_bytes(4), case: :lower)
    File.write!(Path.join(ctx.candidate, marker), "x")

    {2, lines} = VerifyTwin.execute(args(ctx, record(ctx)), producers: dirty_producers())

    texts =
      lines ++
        [
          File.read!(Path.join(ctx.run_root, "receipt.json")),
          File.read!(Path.join(ctx.run_root, "twin-result.json"))
        ]

    # Same reasoning as the floor in the typed-count test: the loop iterates lines plus
    # two file reads (never empty), so the floor pins lines to the four the command prints.
    assert length(lines) == 4

    for text <- texts, secret <- [ctx.candidate, System.user_home!(), marker] do
      refute text =~ secret
    end
  end

  describe "annotate_stop/2" do
    @note "Also check for leftover child processes: the run registry did not answer before the stop timeout, so a child may still be running."
    @passed {0,
             [
               "result: passed (exit 0)",
               "first cause: none",
               "report: R",
               "next action: A"
             ]}

    test "a registry timeout names the cause and appends the note, keeping exit code and report" do
      assert {0, [l1, l2, l3, l4]} =
               VerifyTwin.annotate_stop(@passed, {:error, :registry_timeout})

      assert l1 == "result: passed (exit 0)"
      assert l2 == "first cause: registry_timeout"
      assert l3 == "report: R"
      assert l4 == "next action: A " <> @note
    end

    test "an existing cause is kept and the note is still appended" do
      verdict =
        {1,
         [
           "result: failed (exit 1)",
           "first cause: source_dirty",
           "report: R",
           "next action: A"
         ]}

      assert {1, [_, "first cause: source_dirty", _, l4]} =
               VerifyTwin.annotate_stop(verdict, {:error, :registry_timeout})

      assert l4 == "next action: A " <> @note
    end

    test "a child still alive at stop names the cause and appends its own note" do
      assert {0, [l1, l2, l3, l4]} =
               VerifyTwin.annotate_stop(@passed, {:error, :child_still_alive})

      assert l1 == "result: passed (exit 0)"
      assert l2 == "first cause: child_still_alive"
      assert l3 == "report: R"
      assert l4 =~ ~r/^next action: A .*child.*still (alive|running)/
      refute l4 =~ "did not answer before the stop timeout"
    end

    test "a registry gone at stop names the cause and appends its own note" do
      assert {0, [l1, l2, l3, l4]} = VerifyTwin.annotate_stop(@passed, {:error, :registry_gone})

      assert l1 == "result: passed (exit 0)"
      assert l2 == "first cause: registry_gone"
      assert l3 == "report: R"
      assert l4 =~ ~r/^next action: A .*registry.*(gone|stopped)/
      refute l4 =~ "did not answer before the stop timeout"
    end

    test "a clean stop returns the verdict unchanged" do
      assert VerifyTwin.annotate_stop(@passed, :ok) == @passed
    end
  end
end
