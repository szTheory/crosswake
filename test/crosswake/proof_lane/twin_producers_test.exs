defmodule Crosswake.ProofLane.TwinProducersTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{TwinProducers, TwinReceipt, TwinRuntime}

  @run_id "twin-0123456789abcdef"

  defp rec(kind, launch, value, i, cause \\ nil),
    do: %{kind: kind, launch: launch, seq: i + 1, value: value, cause: cause, i: i}

  defp indexed(list) do
    list
    |> Enum.with_index()
    |> Enum.map(fn {{kind, launch, value}, i} -> rec(kind, launch, value, i) end)
  end

  defp expectations do
    {:ok, exp} =
      TwinReceipt.freeze_expectations(%{
        run_id: @run_id,
        candidate_head: String.duplicate("a", 40),
        candidate_tree: String.duplicate("b", 40),
        lock_digests: [String.duplicate("c", 64)],
        resource_digests: [String.duplicate("d", 64)],
        fixture_digests: [String.duplicate("e", 64)]
      })

    exp
  end

  defp empty_inputs, do: %{cases: %{}, boundary: nil, backend: nil, process: nil}

  defp by_id(observations), do: Map.new(observations, &{&1.id, &1})

  defp all_producers(inputs) do
    exp = expectations()

    base =
      TwinProducers.host_adapter(inputs, @run_id) ++
        TwinProducers.webview(inputs, @run_id) ++
        TwinProducers.app_process(inputs, @run_id) ++
        TwinProducers.fault_boundary(inputs, @run_id) ++
        TwinProducers.phoenix_ecto(inputs, @run_id)

    {base, base ++ TwinProducers.runner(exp, exp.joins, base)}
  end

  describe "producer ownership" do
    test "the union of ids emitted by the six producers equals the 49-id roster, once each" do
      {_base, all} = all_producers(empty_inputs())
      ids = Enum.map(all, & &1.id)
      assert length(ids) == 49
      assert Enum.sort(ids) == Enum.sort(TwinReceipt.roster_ids())
      assert length(Enum.uniq(ids)) == 49
    end

    test "each producer emits exactly its owner's ids with the documented totals" do
      inputs = empty_inputs()
      exp = expectations()

      groups = [
        {:host_adapter, TwinProducers.host_adapter(inputs, @run_id), 8},
        {:webview, TwinProducers.webview(inputs, @run_id), 18},
        {:app_process, TwinProducers.app_process(inputs, @run_id), 2},
        {:fault_boundary, TwinProducers.fault_boundary(inputs, @run_id), 3},
        {:phoenix_ecto, TwinProducers.phoenix_ecto(inputs, @run_id), 10},
        {:runner, TwinProducers.runner(exp, exp.joins, []), 8}
      ]

      roster_owner =
        Map.new(
          for %{sub_observations: subs} <- TwinReceipt.roster(),
              %{id: id, owner: o} <- subs,
              do: {id, o}
        )

      for {owner, observations, count} <- groups do
        assert length(observations) == count
        refute Enum.empty?(observations)
        assert Enum.all?(observations, &(&1.owner == owner and roster_owner[&1.id] == owner))
      end
    end
  end

  describe "webview/2 mapping" do
    defp c1_webview(launch2_first_active) do
      indexed([
        {"main_frame_origin_match", 1, 1},
        {"route_path", 1, "study"},
        {"data_store_persistent", 1, 1},
        {"outbox_selected", 1, 1},
        {"outbox_free_form", 1, 1},
        {"outbox_active", 1, 2},
        {"bridge_forwarded", 1, 1},
        {"host_reply_ok", 1, 1},
        {"main_frame_origin_match", 2, 1},
        {"data_store_persistent", 2, 1},
        {"outbox_active", 2, launch2_first_active},
        {"island_state", 2, "sending"},
        {"outbox_active", 2, 0},
        {"island_state", 2, "saved_account"}
      ])
    end

    test "a launch 1 ending at 2 and a launch 2 starting at 2 pass T03-03 and T05-04" do
      inputs = %{empty_inputs() | cases: %{c1: %{webview: c1_webview(2)}}}
      result = by_id(TwinProducers.webview(inputs, @run_id))
      assert result["TW-T03-03"].outcome == :passed
      assert result["TW-T05-04"].outcome == :passed
      assert result["TW-T06-04"].outcome == :passed
      assert result["TW-T06-05"].outcome == :passed
      assert result["TW-T02-01"].outcome == :passed
      assert result["TW-T05-03"].outcome == :passed
    end

    test "a launch 2 starting at 1 fails T05-04" do
      inputs = %{empty_inputs() | cases: %{c1: %{webview: c1_webview(1)}}}
      result = by_id(TwinProducers.webview(inputs, @run_id))
      assert result["TW-T05-04"].outcome == :failed
      assert result["TW-T05-04"].cause == :contradiction_observed
    end

    test "saved_account before the outbox drained fails T06-05" do
      early =
        indexed([
          {"outbox_active", 1, 2},
          {"island_state", 1, "saved_account"},
          {"outbox_active", 1, 0}
        ])

      inputs = %{empty_inputs() | cases: %{c1: %{webview: early}}}
      assert by_id(TwinProducers.webview(inputs, @run_id))["TW-T06-05"].outcome == :failed
    end

    test "a missing channel file blocks exactly the affected ids with observation_missing" do
      inputs = %{empty_inputs() | cases: %{c1: %{webview: c1_webview(2)}}}
      result = by_id(TwinProducers.webview(inputs, @run_id))
      assert result["TW-T04-06"].outcome == :blocked
      assert result["TW-T04-06"].cause == :observation_missing
      # c1-owned ids keep their own outcomes
      assert result["TW-T03-03"].outcome == :passed

      blocked = for {id, %{outcome: :blocked}} <- result, do: id

      assert Enum.sort(blocked) ==
               Enum.sort(
                 ~w(TW-T04-06 TW-T07-03 TW-T07-04 TW-T07-05 TW-T08-01 TW-T09-01 TW-T09-03 TW-T09-05)
               )
    end

    test "scope fence and disablement rules read the sample order" do
      fence =
        indexed([
          {"outbox_active", 1, 1},
          {"outbox_retained", 1, 1},
          {"island_state", 1, "unavailable"},
          {"outbox_active", 1, 0},
          {"island_state", 1, "fenced"}
        ])

      disabled =
        indexed([
          {"outbox_retained", 1, 0},
          {"outbox_retained", 1, 1},
          {"island_state", 1, "entry_disabled"},
          {"island_state", 1, "unavailable"}
        ])

      inputs = %{empty_inputs() | cases: %{c4: %{webview: fence}, c5: %{webview: disabled}}}
      result = by_id(TwinProducers.webview(inputs, @run_id))
      assert result["TW-T08-01"].outcome == :passed
      assert result["TW-T09-01"].outcome == :passed
      assert result["TW-T09-03"].outcome == :passed
      assert result["TW-T09-05"].outcome == :passed
    end
  end

  describe "channel records" do
    test "records with keys outside kind, launch, seq, value, cause are rejected" do
      good = ~s({"cause":null,"kind":"launch","launch":1,"seq":1,"value":4242})
      bad = ~s({"cause":null,"kind":"launch","launch":1,"seq":1,"value":4242,"extra":1})

      assert {:ok, [%{kind: "launch", value: 4242}]} =
               TwinProducers.parse_channel(:app_process, good)

      assert {:error, :invalid_channel} = TwinProducers.parse_channel(:app_process, bad)
    end

    test "out-of-vocabulary kinds, values and causes are rejected" do
      assert {:error, :invalid_channel} =
               TwinProducers.parse_channel(
                 :webview,
                 ~s({"cause":null,"kind":"answer_text","launch":1,"seq":1,"value":1})
               )

      assert {:error, :invalid_channel} =
               TwinProducers.parse_channel(
                 :webview,
                 ~s({"cause":null,"kind":"island_state","launch":1,"seq":1,"value":"free text"})
               )

      assert {:error, :invalid_channel} =
               TwinProducers.parse_channel(
                 :host_adapter,
                 ~s({"cause":"oops","kind":"TW-T01-01","launch":1,"seq":1,"value":"passed"})
               )
    end
  end

  describe "host_adapter, app_process, boundary and backend rules" do
    test "host adapter verdicts map to outcomes" do
      c1 =
        indexed([
          {"TW-T01-01", 1, "passed"},
          {"TW-T01-02", 1, "failed"},
          {"TW-T01-03", 1, "passed"},
          {"TW-T01-04", 1, "passed"},
          {"TW-T04-02", 1, "passed"},
          {"TW-T04-03", 1, "passed"}
        ])

      inputs = %{empty_inputs() | cases: %{c1: %{host_adapter: c1}}}
      result = by_id(TwinProducers.host_adapter(inputs, @run_id))
      assert result["TW-T01-01"].outcome == :passed
      assert result["TW-T01-02"].outcome == :failed
      assert result["TW-T04-04"].cause == :observation_missing
    end

    test "app process needs two distinct launches, an absent first pid and a stable single install" do
      launches = indexed([{"launch", 1, 111}, {"launch", 2, 222}])

      inputs = %{
        empty_inputs()
        | cases: %{c1: %{app_process: launches}},
          process: %{
            first_pid_absent: true,
            exec_after_install: "x",
            exec_after_c1: "x",
            installs_before_c1: 1
          }
      }

      result = by_id(TwinProducers.app_process(inputs, @run_id))
      assert result["TW-T05-01"].outcome == :passed
      assert result["TW-T05-02"].outcome == :passed

      changed = put_in(inputs.process.exec_after_c1, "y")
      assert by_id(TwinProducers.app_process(changed, @run_id))["TW-T05-02"].outcome == :failed
    end

    test "boundary counters decide the three boundary ids" do
      counters = %{
        "offline" => %{webview_static: %{passed: 0, refused: 3}},
        "offline_install" => %{native_media: %{passed: 0, refused: 1}},
        "playback" => %{}
      }

      inputs = %{
        empty_inputs()
        | boundary: %{counters: counters, epochs: ["offline", "offline_install", "playback"]}
      }

      result = by_id(TwinProducers.fault_boundary(inputs, @run_id))
      assert map_size(result) == 3
      assert Enum.all?(Map.values(result), &(&1.outcome == :passed))

      no_epoch = %{inputs | boundary: %{counters: counters, epochs: ["offline"]}}

      assert by_id(TwinProducers.fault_boundary(no_epoch, @run_id))["TW-T04-07"].outcome ==
               :blocked
    end

    test "backend snapshot deltas decide the Phoenix and Ecto ids" do
      zero_observe = %{
        admitted: 0,
        duplicate_delivery: 0,
        rejected: 0,
        scope_conflict: 0,
        scope_mismatch: 0,
        authorization_denied: 0,
        sigra_denied: 0,
        invalid_envelope: 0,
        synthetic_authority_admitted: 0,
        other_authority_admitted: 0
      }

      zero_rows = %{total: 0, accepted: 0, rejected: 0, distinct: 0, multi_scope: 0}

      backend = %{
        "baseline" => %{observe: zero_observe, rows: zero_rows},
        "replay" => %{
          observe: %{
            zero_observe
            | admitted: 4,
              duplicate_delivery: 2,
              synthetic_authority_admitted: 4
          },
          rows: %{zero_rows | total: 2, accepted: 2, distinct: 2}
        },
        "recovery" => %{
          observe: %{
            zero_observe
            | admitted: 4,
              duplicate_delivery: 2,
              synthetic_authority_admitted: 4,
              rejected: 2,
              scope_conflict: 1
          },
          rows: %{zero_rows | total: 4, accepted: 2, rejected: 2, distinct: 4}
        }
      }

      inputs = %{empty_inputs() | backend: backend}
      result = by_id(TwinProducers.phoenix_ecto(inputs, @run_id))

      for id <- ~w(TW-T02-03 TW-T06-01 TW-T06-02 TW-T06-03 TW-T07-01 TW-T07-02),
          do: assert(result[id].outcome == :passed, id)

      assert result["TW-T08-02"].outcome == :blocked
      assert result["TW-T09-04"].cause == :observation_missing
    end

    test "read_rows opens the database only read-only and returns integers" do
      dir =
        Path.join(System.tmp_dir!(), "twin-rows-" <> Base.encode16(:crypto.strong_rand_bytes(4)))

      File.mkdir_p!(dir)
      on_exit(fn -> File.rm_rf(dir) end)
      db = Path.join(dir, "t.sqlite3")

      {_, 0} =
        System.cmd("sqlite3", [
          db,
          "CREATE TABLE review_events (client_mutation_id TEXT, scope_ref TEXT, status TEXT); " <>
            "INSERT INTO review_events VALUES ('a','s1','accepted'),('b','s1','accepted'),('c','s1','rejected');"
        ])

      assert {:ok, %{total: 3, accepted: 2, rejected: 1, distinct: 3, multi_scope: 0}} =
               TwinProducers.read_rows(runtime(dir), db)

      assert {:error, :rows_unavailable} =
               TwinProducers.read_rows(runtime(dir), Path.join(dir, "absent.sqlite3"))

      refute File.exists?(Path.join(dir, "absent.sqlite3"))
    end
  end

  describe "decode_observe/1" do
    # The body the example backend actually returned in a live diagnostic run (all zero).
    @live_body ~s({"data":{"rejected":0,"synthetic_authority_admitted":0,"other_authority_admitted":0,"duplicate_delivery":0,"authority_unavailable":0,"authorization_denied":0,"feature_disabled":0,"invalid_envelope":0,"scope_conflict":0,"scope_mismatch":0,"sigra_denied":0,"transaction_failed":0,"admitted":0}})

    test "decodes the real backend body, including counters the runner never names" do
      assert {:ok, counters} = TwinProducers.decode_observe(@live_body)
      assert map_size(counters) == 13
      assert counters.feature_disabled == 0
      assert counters.transaction_failed == 0
    end

    test "matches the example backend's own counter list" do
      source =
        File.read!("examples/phoenix_host/lib/crosswake_example/e2e/twin_fault_controller.ex")

      backend =
        for name <- ~w(denial_counters outcome_counters authority_counters),
            [_, list] <- Regex.scan(~r/@#{name} ~w\(([^)]*)\)a/, source),
            key <- String.split(list),
            do: key

      body = Jason.encode!(%{data: Map.new(backend, &{&1, 1})})
      assert length(backend) == 13
      assert {:ok, _} = TwinProducers.decode_observe(body)
    end

    test "refuses a missing, extra, negative or non-integer counter" do
      data = Jason.decode!(@live_body)["data"]

      for bad <- [
            Map.delete(data, "admitted"),
            Map.put(data, "unexpected", 0),
            Map.put(data, "admitted", -1),
            Map.put(data, "admitted", "1")
          ] do
        assert {:error, :observe_unavailable} =
                 TwinProducers.decode_observe(Jason.encode!(%{data: bad}))
      end

      assert {:error, :observe_unavailable} = TwinProducers.decode_observe("not json")
    end
  end

  describe "runner/3" do
    test "the six in-run controls pass and the real observations are left unchanged" do
      exp = expectations()
      {base, all} = all_producers(empty_inputs())
      snapshot = :erlang.term_to_binary(base)
      runner = TwinProducers.runner(exp, exp.joins, base)
      assert :erlang.term_to_binary(base) == snapshot

      result = by_id(runner)

      for id <-
            ~w(TW-T10-03 TW-T10-04 TW-T10-05 TW-T10-06 TW-T10-07 TW-T10-08 TW-T10-01 TW-T10-02) do
        assert result[id].outcome == :passed, id
      end

      assert {:ok, receipt} = TwinReceipt.derive(exp, exp.joins, all)
      # the run's own observations (all blocked here) decide the receipt; controls never alter it
      assert receipt.overall_status == :blocked
    end

    test "an incomplete observation set fails TW-T10-01" do
      exp = expectations()
      result = by_id(TwinProducers.runner(exp, exp.joins, []))
      assert result["TW-T10-01"].outcome == :failed
    end
  end

  defp repo_fixture(_context) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "twin-freeze-" <> Base.encode16(:crypto.strong_rand_bytes(4))
      )

    host = Path.join(dir, "examples/phoenix_host")
    fixtures = Path.join(host, "native/ios/crosswake_shell/Fixtures")

    media_dir =
      Path.join(host, "native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle")

    File.mkdir_p!(fixtures)
    File.mkdir_p!(media_dir)
    File.mkdir_p!(Path.join(host, "priv/static"))
    File.write!(Path.join(dir, "mix.lock"), "%{}\n")
    File.write!(Path.join(host, "mix.lock"), "%{a: 1}\n")
    File.write!(Path.join(fixtures, "crosswake_manifest.json"), "{\"m\":1}")
    File.write!(Path.join(fixtures, "route_activation.json"), "{\"a\":1}")
    File.write!(Path.join(media_dir, "pronunciation.aiff"), "synthetic media")
    File.write!(Path.join(host, "priv/static/offline_study.js"), "// js")
    # Identity files and the run root live beside the repository, never inside it.
    side = dir <> "-side"
    File.mkdir_p!(side)
    git(dir, ["init", "-q"])
    git(dir, ["add", "-A"])
    git(dir, ["commit", "-q", "-m", "fixture"])

    {head, 0} = git(dir, ["rev-parse", "HEAD"])
    {tree, 0} = git(dir, ["rev-parse", "HEAD^{tree}"])
    on_exit(fn -> File.rm_rf(dir) end)
    on_exit(fn -> File.rm_rf(side) end)

    identity = fn overrides ->
      {:ok, media} = TwinProducers.file_digest(Path.join(media_dir, "pronunciation.aiff"))

      {:ok, manifest} =
        TwinProducers.file_digest(Path.join(fixtures, "crosswake_manifest.json"))

      {:ok, activation} =
        TwinProducers.file_digest(Path.join(fixtures, "route_activation.json"))

      base = %{
        "media" => %{"sha256" => media, "size" => 15},
        "generated" => %{"manifest_sha256" => manifest, "activation_sha256" => activation}
      }

      path = Path.join(side, "identity-#{System.unique_integer([:positive])}.json")
      File.write!(path, Jason.encode!(Map.merge(base, overrides)))
      path
    end

    runtime = %{
      runtime(side)
      | candidate_path: dir,
        candidate_head: String.trim(head),
        candidate_tree: String.trim(tree)
    }

    {:ok,
     dir: dir,
     side: side,
     runtime: runtime,
     identity: identity,
     media: Path.join(media_dir, "pronunciation.aiff")}

    {:ok,
     dir: dir,
     side: side,
     runtime: runtime,
     identity: identity,
     media: Path.join(media_dir, "pronunciation.aiff")}
  end

  # Isolated real git: no user or system config, fixed dates, no signing.
  defp git_env(dir) do
    home = dir <> "-side/home"
    File.mkdir_p!(home)

    [
      {"HOME", home},
      {"XDG_CONFIG_HOME", Path.join(home, ".config")},
      {"GIT_CONFIG_NOSYSTEM", "1"},
      {"GIT_CONFIG_GLOBAL", "/dev/null"},
      {"GIT_AUTHOR_DATE", "2026-01-01T00:00:00Z"},
      {"GIT_COMMITTER_DATE", "2026-01-01T00:00:00Z"}
    ]
  end

  defp git(dir, args) do
    {out, 0} =
      System.cmd(
        "git",
        [
          "-c",
          "user.name=t",
          "-c",
          "user.email=t@example.test",
          "-c",
          "commit.gpgsign=false",
          "-c",
          "core.autocrlf=false",
          "-C",
          dir | args
        ],
        env: git_env(dir),
        stderr_to_stdout: true
      )

    {String.trim(out), 0}
  end

  defp live(frozen, extra \\ %{}) do
    js = frozen.study_js

    Map.merge(
      %{
        installed_manifest: frozen.identity.manifest,
        installed_activation: frozen.identity.activation,
        installed_media: frozen.identity.media,
        executable_stable: true,
        served_js: js,
        backend_build: frozen.backend_build
      },
      extra
    )
  end

  describe "freeze/3 and observe_identities/2" do
    setup :repo_fixture

    test "freeze blocks with identity_unknown when media or generated values are missing", ctx do
      opts = [backend_digest: fn -> {:ok, String.duplicate("9", 64)} end]
      no_media = ctx.identity.(%{"media" => %{}})
      no_generated = ctx.identity.(%{"generated" => %{}})
      assert {:blocked, :identity_unknown} = TwinProducers.freeze(ctx.runtime, no_media, opts)
      assert {:blocked, :identity_unknown} = TwinProducers.freeze(ctx.runtime, no_generated, opts)

      assert {:blocked, :identity_unknown} =
               TwinProducers.freeze(ctx.runtime, Path.join(ctx.dir, "none.json"), opts)
    end

    test "matching identities pass every join; the freeze is written without answers", ctx do
      assert {:ok, frozen} =
               TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}),
                 backend_digest: fn -> {:ok, String.duplicate("9", 64)} end
               )

      assert File.exists?(Path.join(ctx.runtime.run_root, "expectations.json"))
      observed = TwinProducers.observe_identities(frozen, live(frozen))
      assert observed == frozen.expectations.joins
    end

    test "a tracked media fixture that no longer matches the identity fails TW-T10-02", ctx do
      {:ok, frozen} =
        TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}),
          backend_digest: fn -> {:ok, String.duplicate("9", 64)} end
        )

      File.write!(ctx.media, "tampered media")
      observed = TwinProducers.observe_identities(frozen, live(frozen))
      refute observed.installed_media == frozen.expectations.joins.installed_media

      exp = frozen.expectations
      result = by_id(TwinProducers.runner(exp, observed, []))
      assert result["TW-T10-02"].outcome == :failed
    end

    test "an unknown identity part blocks instead of passing", ctx do
      {:ok, frozen} =
        TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}),
          backend_digest: fn -> {:ok, String.duplicate("9", 64)} end
        )

      observed =
        TwinProducers.observe_identities(
          frozen,
          live(frozen, %{installed_media: nil, backend_build: nil})
        )

      refute Map.has_key?(observed, :installed_media)
      refute Map.has_key?(observed, :backend_build)
      result = by_id(TwinProducers.runner(frozen.expectations, observed, []))
      assert result["TW-T10-02"].outcome == :blocked
    end

    test "a different backend build digest fails the backend join", ctx do
      {:ok, frozen} =
        TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}),
          backend_digest: fn -> {:ok, String.duplicate("9", 64)} end
        )

      observed =
        TwinProducers.observe_identities(
          frozen,
          live(frozen, %{backend_build: String.duplicate("8", 64)})
        )

      refute observed.backend_build == frozen.expectations.joins.backend_build
    end
  end

  describe "source cleanliness" do
    setup :repo_fixture

    defp frozen_opts, do: [backend_digest: fn -> {:ok, String.duplicate("9", 64)} end]

    defp env_restore(name) do
      old = System.get_env(name)

      on_exit(fn ->
        if old, do: System.put_env(name, old), else: System.delete_env(name)
      end)
    end

    defp expectations_path(ctx), do: Path.join(ctx.runtime.run_root, "expectations.json")

    test "a clean checkout passes the guard and freezes", ctx do
      assert TwinProducers.clean_tree(ctx.dir) == :ok
      assert TwinProducers.dirty_count(ctx.dir) == 0
      assert {:ok, _frozen} = TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts())
    end

    test "a modified tracked file blocks the freeze before anything is written", ctx do
      File.write!(Path.join(ctx.dir, "mix.lock"), "%{changed: true}\n")

      assert TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts()) ==
               {:blocked, :source_dirty}

      assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
      refute File.exists?(expectations_path(ctx))
    end

    test "a staged-only change blocks", ctx do
      File.write!(Path.join(ctx.dir, "mix.lock"), "%{staged: true}\n")
      git(ctx.dir, ["add", "mix.lock"])
      assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
    end

    test "a deleted tracked file blocks", ctx do
      File.rm!(Path.join(ctx.dir, "mix.lock"))
      assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
    end

    test "an untracked file blocks", ctx do
      File.write!(Path.join(ctx.dir, "new.ex"), "defmodule New do\nend\n")
      assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
      assert TwinProducers.dirty_count(ctx.dir) == 1
    end

    test "a staged rename blocks and counts as two findings", ctx do
      git(ctx.dir, ["mv", "mix.lock", "renamed.lock"])
      assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
      assert TwinProducers.dirty_count(ctx.dir) == 2
    end

    test "one modified and one untracked file count two", ctx do
      File.write!(Path.join(ctx.dir, "mix.lock"), "%{changed: true}\n")
      File.write!(Path.join(ctx.dir, "extra.ex"), "x\n")
      assert TwinProducers.dirty_count(ctx.dir) == 2
    end

    test "a file ignored by the repository gitignore does not block", ctx do
      File.write!(Path.join(ctx.dir, ".gitignore"), "ignored.tmp\n")
      git(ctx.dir, ["add", ".gitignore"])
      git(ctx.dir, ["commit", "-q", "-m", "ignore"])
      File.write!(Path.join(ctx.dir, "ignored.tmp"), "x\n")
      assert TwinProducers.clean_tree(ctx.dir) == :ok
    end

    test "a file hidden only by a user-global ignore file still blocks", ctx do
      home = Path.join(ctx.side, "global-home")
      File.mkdir_p!(Path.join(home, ".config/git"))
      File.write!(Path.join(home, ".config/git/ignore"), "hidden-by-global.txt\n")
      env_restore("HOME")
      env_restore("XDG_CONFIG_HOME")
      System.put_env("HOME", home)
      System.put_env("XDG_CONFIG_HOME", Path.join(home, ".config"))
      File.write!(Path.join(ctx.dir, "hidden-by-global.txt"), "x\n")

      # Control: an ordinary git status in this environment sees nothing.
      assert System.cmd("git", ["-C", ctx.dir, "status", "--porcelain"], stderr_to_stdout: true) ==
               {"", 0}

      assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
    end

    test "an info/exclude rule blocks; comments, blanks and a missing file do not", ctx do
      exclude = Path.join(ctx.dir, ".git/info/exclude")
      File.rm(exclude)
      assert TwinProducers.clean_tree(ctx.dir) == :ok

      File.mkdir_p!(Path.dirname(exclude))
      File.write!(exclude, "# only a comment\n\n   \n")
      assert TwinProducers.clean_tree(ctx.dir) == :ok
      assert TwinProducers.dirty_count(ctx.dir) == 0

      File.write!(exclude, "# comment\nsecret.txt\n")
      assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
      assert TwinProducers.dirty_count(ctx.dir) == 1
    end

    test "an inherited GIT_DIR does not redirect the probe", ctx do
      other = ctx.dir <> "-other"
      File.mkdir_p!(other)
      on_exit(fn -> File.rm_rf(other) end)
      git(other, ["init", "-q"])
      git(other, ["commit", "-q", "--allow-empty", "-m", "empty"])
      env_restore("GIT_DIR")
      System.put_env("GIT_DIR", Path.join(other, ".git"))

      File.write!(Path.join(ctx.dir, "new.ex"), "x\n")
      assert TwinProducers.clean_tree(ctx.dir) == {:blocked, :source_dirty}
      File.rm!(Path.join(ctx.dir, "new.ex"))
      assert {:ok, frozen} = TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts())
      assert frozen.head == ctx.runtime.candidate_head
    end

    test "an unavailable git and a non-repository block with prerequisite_missing", ctx do
      gone = fn _cmd, _args, _opts -> raise ErlangError, original: :enoent end
      assert TwinProducers.clean_tree(ctx.dir, git_cmd: gone) == {:blocked, :prerequisite_missing}
      assert TwinProducers.dirty_count(ctx.dir, git_cmd: gone) == nil

      plain = Path.join(ctx.side, "not-a-repo")
      File.mkdir_p!(plain)

      captured =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          send(self(), {:result, TwinProducers.clean_tree(plain)})
        end)

      assert_received {:result, {:blocked, :prerequisite_missing}}
      assert captured == ""
      assert TwinProducers.dirty_count(plain) == nil
    end

    test "every git invocation discards stderr at the descriptor level", ctx do
      bin = Path.join(ctx.side, "fakebin")
      sentinel = Path.join(ctx.side, "stderr-sentinel")
      File.mkdir_p!(bin)

      real_git = System.find_executable("git")

      script = """
      #!/bin/sh
      if [ /dev/fd/2 -ef /dev/null ]; then echo null >> "#{sentinel}"; else echo leak >> "#{sentinel}"; fi
      exec "#{real_git}" "$@"
      """

      File.write!(Path.join(bin, "git"), script)
      File.chmod!(Path.join(bin, "git"), 0o755)
      env_restore("PATH")
      System.put_env("PATH", bin <> ":" <> System.get_env("PATH"))

      assert TwinProducers.clean_tree(ctx.dir) == :ok
      assert TwinProducers.dirty_count(ctx.dir) == 0
      assert {:ok, _} = TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts())

      lines = sentinel |> File.read!() |> String.split()
      assert Enum.uniq(lines) == ["null"]
      assert length(lines) >= 8
    end

    test "the recorded twin-03 shape (untracked files plus modified tracked ones) blocks", ctx do
      File.mkdir_p!(Path.join(ctx.dir, "lib/crosswake/proof_lane"))
      File.write!(Path.join(ctx.dir, "lib/crosswake/proof_lane/twin_new.ex"), "x\n")

      File.write!(
        Path.join(ctx.dir, "examples/phoenix_host/priv/static/offline_study.js"),
        "// js2"
      )

      File.write!(Path.join(ctx.dir, "mix.lock"), "%{moved: 1}\n")

      assert TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts()) ==
               {:blocked, :source_dirty}
    end

    test "file names never leave the probe", ctx do
      marker = "zz-leak-marker-" <> Base.encode16(:crypto.strong_rand_bytes(4))
      File.write!(Path.join(ctx.dir, marker), "x\n")
      parent = self()

      out =
        ExUnit.CaptureIO.capture_io(fn ->
          err =
            ExUnit.CaptureIO.capture_io(:stderr, fn ->
              send(
                parent,
                {:result, TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts())}
              )
            end)

          send(parent, {:err, err})
        end)

      assert_received {:result, result}
      assert_received {:err, err}
      assert result == {:blocked, :source_dirty}
      refute inspect(result) =~ marker
      refute out =~ marker
      refute err =~ marker
      refute File.exists?(expectations_path(ctx))
    end

    test "a tree dirtied after freeze leaves the source and build joins absent", ctx do
      {:ok, frozen} = TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts())
      File.write!(Path.join(ctx.dir, "late.ex"), "x\n")

      observed = TwinProducers.observe_identities(frozen, live(frozen))
      refute Map.has_key?(observed, :source)
      refute Map.has_key?(observed, :installed_build)

      assert by_id(TwinProducers.runner(frozen.expectations, observed, []))["TW-T10-02"].outcome ==
               :blocked

      assert TwinProducers.checked_identities(frozen, live(frozen)) == {:blocked, :source_dirty}
    end

    test "a HEAD that moved after freeze leaves the source and build joins absent", ctx do
      {:ok, frozen} = TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts())
      File.write!(Path.join(ctx.dir, "later.ex"), "x\n")
      git(ctx.dir, ["add", "later.ex"])
      git(ctx.dir, ["commit", "-q", "-m", "later"])

      observed = TwinProducers.observe_identities(frozen, live(frozen))
      refute Map.has_key?(observed, :source)
      refute Map.has_key?(observed, :installed_build)
    end

    test "an unchanged checkout passes through checked_identities unchanged", ctx do
      {:ok, frozen} = TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts())

      assert {:ok, observed} = TwinProducers.checked_identities(frozen, live(frozen))
      assert observed == frozen.expectations.joins
    end

    test "observation also loses the backend join when the tree is not clean (fail closed)",
         ctx do
      {:ok, frozen} = TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), frozen_opts())
      File.write!(Path.join(ctx.dir, "late.ex"), "x\n")
      observed = TwinProducers.observe_identities(frozen, live(frozen))
      refute Map.has_key?(observed, :backend_build)
    end
  end

  defp runtime(dir) do
    {:ok, registry} = Agent.start_link(fn -> %{children: %{}, first_failure: nil} end)

    %TwinRuntime{
      run_id: @run_id,
      run_root: dir,
      database_path: Path.join(dir, "twin.sqlite3"),
      origin: "http://127.0.0.1:1",
      origin_port: 1,
      registry: registry,
      run_deadline_at: System.monotonic_time(:millisecond) + 60_000
    }
  end
end
