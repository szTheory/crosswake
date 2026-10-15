defmodule Crosswake.ProofLane.TwinJourney do
  @moduledoc """
  Orchestrates the single bounded twin run inside `verify_twin`.

  Order: tools -> run-owned Phoenix child (private loopback port, run-root database, listener
  ownership verified) -> loopback fault boundary on the held origin -> one owned simulator ->
  `xcodebuild build-for-testing` -> exactly one `simctl install` -> capture canary (zero exported
  attachments required) -> the five case methods, resetting the owned app context only between
  cases -> channel files, epoch snapshots and independent identity observations -> producers.

  Every resource the run starts is torn down in `finish/2`: the boundary, the Phoenix child,
  the owned simulator (by the UDID this run created) and the run-root residue (result bundles,
  derived data, databases). `xcodebuild` output is reduced to closed classifications and test
  method names; raw output is never retained. Nothing here knows an answer, media byte, URL,
  scope value or device identifier.
  """

  alias Crosswake.ProofLane.{TwinFaultBoundary, TwinProducers, TwinRuntime}

  @bundle_id "org.crosswake.twin"
  @scheme "CrosswakeShell"
  @test_plan "TwinJourney"
  @project_rel "examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell.xcodeproj"
  @host_rel "examples/phoenix_host"
  @cases [
    {:c1, "test_01_uninterrupted_journey"},
    {:c2, "test_02_media_faults"},
    {:c3, "test_03_rejection_conflict"},
    {:c4, "test_04_scope_fence"},
    {:c5, "test_05_disablement"}
  ]
  @canary "CrosswakeShellUITests/TwinCaptureCanaryUITests/test_capture_canary"
  @classes [:succeeded, :failed, :build_failed, :timeout, :cause_not_retained]
  @attachment_reasons [:no_result_bundle, :export_failed, :manifest_unreadable]
  @stages_file "run-stages.json"

  # ------------------------------------------------------------------ pure helpers

  @doc """
  `xcodebuild` arguments. `mode` is `:build` or `{:test, only_testing}`. The result bundle
  and derived data are inside the run root. There is deliberately no option that keeps
  screenshots or attachments.
  """
  @spec xcodebuild_args(:build | {:test, String.t()}, map()) :: [String.t()]
  def xcodebuild_args(mode, ctx) do
    {verb, extra} =
      case mode do
        :build -> {"build-for-testing", []}
        {:test, only} -> {"test-without-building", ["-only-testing:" <> only]}
      end

    bundle = Map.get(ctx, :result_bundle, "result")

    [
      verb,
      "-project",
      ctx.project,
      "-scheme",
      @scheme,
      "-testPlan",
      @test_plan,
      "-destination",
      "platform=iOS Simulator,id=" <> ctx.udid,
      "-derivedDataPath",
      Path.join(ctx.run_root, "dd"),
      "-resultBundlePath",
      Path.join(ctx.run_root, bundle <> ".xcresult")
    ] ++
      extra ++
      [
        "ONLY_ACTIVE_ARCH=YES",
        "CODE_SIGNING_ALLOWED=NO",
        "TEST_RUNNER_CROSSWAKE_TWIN_CONTROL_PORT=" <> Integer.to_string(ctx.control_port)
      ]
  end

  @doc "The same control port as an environment entry, which is what the test runner reads."
  @spec xcodebuild_env(map()) :: [{String.t(), String.t()}]
  def xcodebuild_env(ctx),
    do: [{"TEST_RUNNER_CROSSWAKE_TWIN_CONTROL_PORT", Integer.to_string(ctx.control_port)}]

  @doc """
  Reduces raw `xcodebuild` output to a closed class and the test method names it mentions.
  The text itself is not returned.
  """
  @spec classify_output(binary(), integer() | :timeout) :: %{class: atom(), tests: [String.t()]}
  def classify_output(_text, :timeout), do: %{class: :timeout, tests: []}

  def classify_output(text, status) do
    tests =
      ~r/Test Case '-\[\S+ (test_[a-z0-9_]+)\]' (?:passed|failed)/
      |> Regex.scan(text)
      |> Enum.map(&Enum.at(&1, 1))
      |> Enum.uniq()

    class =
      cond do
        String.contains?(text, ["** TEST BUILD FAILED **", "** BUILD FAILED **"]) ->
          :build_failed

        status == 0 and
            String.contains?(text, [
              "** TEST EXECUTE SUCCEEDED **",
              "** TEST SUCCEEDED **",
              "** TEST BUILD SUCCEEDED **"
            ]) ->
          :succeeded

        String.contains?(text, ["** TEST EXECUTE FAILED **", "** TEST FAILED **"]) ->
          :failed

        true ->
          :cause_not_retained
      end

    %{class: class, tests: tests}
  end

  def classes, do: @classes

  @doc """
  Removes every result bundle, exported attachment directory, derived-data tree, database and
  media copy from the run root. Returns `{:error, :residue}` if any `.xcresult` remains.
  """
  @spec cleanup(Path.t()) :: :ok | {:error, :residue}
  def cleanup(run_root) do
    root = Path.expand(run_root)

    protected =
      Enum.map(
        [System.user_home!(), System.tmp_dir!(), "/", "/tmp", "/private/tmp", "/var"],
        &Path.expand/1
      )

    if root in protected or length(Path.split(root)) < 4 do
      {:error, :residue}
    else
      File.rm_rf(Path.join(root, "dd"))

      # Only the run root itself and its known children are searched, never a deep tree.
      patterns = [
        "*.xcresult",
        "*/*.xcresult",
        "att-*",
        "*.sqlite3*",
        "*.db",
        "*.db-*",
        "*.aiff",
        "obs/*/*.aiff"
      ]

      for pattern <- patterns, path <- Path.wildcard(Path.join(root, pattern), match_dot: true) do
        File.rm_rf(path)
      end

      residue =
        Path.wildcard(Path.join(root, "*.xcresult")) ++
          Path.wildcard(Path.join(root, "*/*.xcresult"))

      if residue == [], do: :ok, else: {:error, :residue}
    end
  end

  # ------------------------------------------------------------------ the run

  @doc """
  Runs the journey and returns `{:ok, observed_identities, observations}` or
  `{:blocked, cause}`. `frozen` is the result of `TwinProducers.freeze/3`.
  """
  @spec run(TwinRuntime.t(), map(), keyword()) :: {:ok, map(), [map()]} | {:blocked, atom()}
  def run(runtime, frozen, opts \\ []) do
    {:ok, store} =
      Agent.start_link(fn -> %{snapshots: %{}, installs: 0, cases: %{}, stages: []} end)

    ctx = %{
      runtime: runtime,
      frozen: frozen,
      store: store,
      run_root: runtime.run_root,
      opts: opts
    }

    result =
      try do
        orchestrate(ctx)
      rescue
        _ -> {:blocked, :cause_not_retained}
      catch
        _, _ -> {:blocked, :cause_not_retained}
      end

    finish(ctx, result)
  end

  defp orchestrate(ctx) do
    with {:ok, tools} <- tools(),
         ctx = Map.put(ctx, :tools, tools),
         {:ok, ctx} <- start_backend(ctx),
         {:ok, ctx} <- start_boundary(ctx),
         {:ok, ctx} <- create_simulator(ctx),
         {:ok, ctx} <- build_and_install(ctx),
         :ok <- capture_canary(ctx),
         {:ok, ctx} <- run_cases(ctx) do
      assemble(ctx)
    end
  end

  # ---- tools

  defp tools do
    names = ~w(xcrun xcodebuild sqlite3 lsof mix git)

    found =
      for name <- names,
          path = System.find_executable(name),
          into: %{},
          do: {String.to_atom(name), path}

    if map_size(found) == length(names), do: {:ok, found}, else: {:blocked, :prerequisite_missing}
  end

  # ---- backend

  defp start_backend(ctx) do
    runtime = ctx.runtime
    host = Path.join(runtime.candidate_path, @host_rel)

    with true <- String.starts_with?(runtime.database_path, runtime.run_root <> "/"),
         {:ok, port} <- free_port(),
         env = TwinRuntime.env_for_backend(runtime, port),
         {:ok, _out, 0} <-
           TwinProducers.capture(runtime, :migrate, ctx.tools.mix, ["ecto.migrate"],
             cd: host,
             env: env,
             deadline_ms: 300_000
           ),
         {:ok, child} <-
           TwinRuntime.start_child(runtime, :phoenix, %{
             path: "/bin/sh",
             args: ["-c", "exec \"$0\" phx.server >/dev/null 2>&1", ctx.tools.mix],
             env: env,
             cd: host,
             deadline_ms: 3_600_000
           }),
         :ok <- await_backend(port, 120_000),
         :ok <- TwinFaultBoundary.verify_upstream_owner(runtime, port: port, os_pid: child.os_pid) do
      {:ok, Map.merge(ctx, %{upstream_port: port, phoenix: child})}
    else
      {:blocked, _} = blocked -> blocked
      _ -> {:blocked, :prerequisite_missing}
    end
  end

  defp await_backend(port, budget) do
    deadline = System.monotonic_time(:millisecond) + budget
    poll_backend(port, deadline)
  end

  defp poll_backend(port, deadline) do
    case TwinFaultBoundary.upstream_request(port, "GET", "/_e2e/twin/build") do
      {:ok, 200, _} ->
        :ok

      _ ->
        if System.monotonic_time(:millisecond) > deadline do
          {:blocked, :child_timeout}
        else
          Process.sleep(500)
          poll_backend(port, deadline)
        end
    end
  end

  defp free_port do
    with {:ok, listener} <- :gen_tcp.listen(0, ip: {127, 0, 0, 1}, active: false),
         {:ok, port} <- :inet.port(listener) do
      :gen_tcp.close(listener)
      {:ok, port}
    end
  end

  # ---- boundary and snapshots

  defp start_boundary(ctx) do
    store = ctx.store
    runtime = ctx.runtime
    upstream = ctx.upstream_port

    snapshot = fn epoch -> store_snapshot(store, runtime, upstream, epoch) end
    store_snapshot(store, runtime, upstream, "baseline")

    case TwinFaultBoundary.start(
           origin_listener: runtime.origin_listener,
           upstream_port: upstream,
           snapshot: snapshot
         ) do
      {:ok, boundary} ->
        {:ok,
         Map.merge(ctx, %{
           boundary: boundary,
           control_port: TwinFaultBoundary.control_port(boundary)
         })}

      _ ->
        {:blocked, :prerequisite_missing}
    end
  end

  defp store_snapshot(store, runtime, upstream, name) do
    with {:ok, observe} <- TwinProducers.read_observe(upstream),
         {:ok, rows} <- TwinProducers.read_rows(runtime, runtime.database_path) do
      Agent.update(store, &put_in(&1, [:snapshots, name], %{observe: observe, rows: rows}))
    else
      _ -> :unavailable
    end
  end

  # ---- simulator

  defp create_simulator(ctx) do
    xcrun = ctx.tools.xcrun
    runtime = ctx.runtime

    with {:ok, listing, 0} <-
           TwinProducers.capture(runtime, :sim_list, xcrun, [
             "simctl",
             "list",
             "-j",
             "devicetypes",
             "runtimes"
           ]),
         {:ok, %{"devicetypes" => types, "runtimes" => runtimes}} <- Jason.decode(listing),
         {:ok, type_id} <- pick_device_type(types),
         {:ok, runtime_id} <- pick_runtime(runtimes),
         {:ok, out, 0} <-
           TwinProducers.capture(runtime, :sim_create, xcrun, [
             "simctl",
             "create",
             "crosswake-phase180-twin-" <> runtime.run_id,
             type_id,
             runtime_id
           ]),
         udid = String.trim(out),
         true <- Regex.match?(~r/\A[0-9A-F-]{36}\z/, udid),
         _ = Agent.update(ctx.store, &Map.put(&1, :udid, udid)),
         {:ok, _, 0} <-
           TwinProducers.capture(runtime, :sim_boot, xcrun, ["simctl", "boot", udid],
             deadline_ms: 180_000
           ),
         {:ok, _, 0} <-
           TwinProducers.capture(
             runtime,
             :sim_status,
             xcrun,
             ["simctl", "bootstatus", udid, "-b"],
             deadline_ms: 300_000
           ) do
      {:ok,
       Map.merge(ctx, %{
         udid: udid,
         project: Path.join(runtime.candidate_path, @project_rel),
         app_path:
           Path.join(
             runtime.run_root,
             "dd/Build/Products/Debug-iphonesimulator/CrosswakeShell.app"
           )
       })}
    else
      _ -> {:blocked, :prerequisite_missing}
    end
  end

  defp pick_device_type(types) do
    ids = for %{"identifier" => id} <- types, String.contains?(id, "iPhone"), do: id
    preferred = Enum.find(ids, &String.ends_with?(&1, "iPhone-17")) || List.first(ids)
    if preferred, do: {:ok, preferred}, else: :error
  end

  defp pick_runtime(runtimes) do
    candidates =
      for %{"identifier" => id, "name" => "iOS " <> version, "isAvailable" => true} <- runtimes,
          do: {version_key(version), id}

    case Enum.sort(candidates) do
      [] -> :error
      sorted -> {:ok, sorted |> List.last() |> elem(1)}
    end
  end

  defp version_key(version),
    do: version |> String.split(".") |> Enum.map(&(Integer.parse(&1) |> elem(0)))

  # ---- build and the single install

  defp build_and_install(ctx) do
    args = xcodebuild_args(:build, Map.put(ctx, :result_bundle, "rb-build"))

    with {:ok, %{class: :succeeded}} <- xcodebuild(ctx, :build, args, 1_800_000),
         {:ok, _, 0} <-
           TwinProducers.capture(
             ctx.runtime,
             :install,
             ctx.tools.xcrun,
             ["simctl", "install", ctx.udid, ctx.app_path],
             deadline_ms: 120_000
           ),
         {:ok, digest} <- TwinProducers.file_digest(Path.join(ctx.app_path, "CrosswakeShell")) do
      Agent.update(
        ctx.store,
        &(&1 |> Map.put(:installs, 1) |> Map.put(:exec_after_install, digest))
      )

      {:ok, ctx}
    else
      _ -> {:blocked, :prerequisite_missing}
    end
  end

  defp xcodebuild(ctx, name, args, deadline_ms) do
    case TwinProducers.capture(
           ctx.runtime,
           :"xcodebuild_#{name}_#{System.unique_integer([:positive])}",
           ctx.tools.xcodebuild,
           args,
           env: xcodebuild_env(ctx),
           deadline_ms: deadline_ms
         ) do
      {:ok, text, status} -> {:ok, classify_output(text, status)}
      {:error, :timeout} -> {:ok, classify_output("", :timeout)}
      other -> other
    end
  end

  # ---- capture canary (D-21)

  defp capture_canary(ctx) do
    control(ctx, "POST", "/refuse")
    args = xcodebuild_args({:test, @canary}, Map.put(ctx, :result_bundle, "rb-canary"))
    result = xcodebuild(ctx, :canary, args, 600_000)
    control(ctx, "POST", "/pass")
    count = attachment_count(ctx, "rb-canary", "att-canary")
    record_stage(ctx, :canary, result, count)

    case {result, count} do
      {{:ok, %{class: :failed}}, {:ok, 0}} -> :ok
      {{:ok, %{class: :failed}}, {:ok, _}} -> {:blocked, :capture_not_prevented}
      _ -> {:blocked, :attachment_check_unavailable}
    end
  end

  # Retains a privacy-safe class for every runner stage (D-16): the xcodebuild class and why an
  # attachment check could or could not count, never output text, paths or identifiers.
  defp record_stage(ctx, stage, result, count) do
    xcodebuild =
      case result do
        {:ok, %{class: class}} when class in @classes -> class
        _ -> :cause_not_retained
      end

    attachments =
      case count do
        {:ok, 0} -> :counted_zero
        {:ok, _} -> :counted_nonzero
        {:unavailable, reason} when reason in @attachment_reasons -> reason
        _ -> :cause_not_retained
      end

    entry = %{stage: stage, xcodebuild: xcodebuild, attachments: attachments}
    Agent.update(ctx.store, &Map.update!(&1, :stages, fn stages -> stages ++ [entry] end))
  end

  # Exports every attachment from a result bundle and returns how many exist. Zero is required.
  defp attachment_count(ctx, bundle, out_name) do
    path = Path.join(ctx.run_root, bundle <> ".xcresult")
    out = Path.join(ctx.run_root, out_name)

    with {:bundle, true} <- {:bundle, File.dir?(path)},
         {:export, {:ok, _, 0}} <-
           {:export,
            TwinProducers.capture(ctx.runtime, :"export_#{out_name}", ctx.tools.xcrun, [
              "xcresulttool",
              "export",
              "attachments",
              "--path",
              path,
              "--output-path",
              out
            ])},
         {:manifest, {:ok, manifest}} <- {:manifest, File.read(Path.join(out, "manifest.json"))},
         {:manifest, {:ok, entries}} when is_list(entries) <- {:manifest, Jason.decode(manifest)} do
      listed = Enum.sum(for %{"attachments" => attachments} <- entries, do: length(attachments))
      files = out |> File.ls!() |> Enum.reject(&(&1 == "manifest.json")) |> length()
      {:ok, max(listed, files)}
    else
      {:bundle, _} -> {:unavailable, :no_result_bundle}
      {:export, _} -> {:unavailable, :export_failed}
      {:manifest, _} -> {:unavailable, :manifest_unreadable}
    end
  end

  # ---- cases

  defp run_cases(ctx) do
    Enum.reduce_while(@cases, {:ok, ctx}, fn {case_id, method}, {:ok, ctx} ->
      case run_case(ctx, case_id, method) do
        :ok -> {:cont, {:ok, ctx}}
        {:blocked, _} = blocked -> {:halt, blocked}
      end
    end)
  end

  defp run_case(ctx, case_id, method) do
    xcrun = ctx.tools.xcrun
    runtime = ctx.runtime

    # The owned context is reset only between case methods, never inside one.
    reset =
      if case_id == :c1 do
        :ok
      else
        TwinProducers.capture(runtime, :terminate, xcrun, [
          "simctl",
          "terminate",
          ctx.udid,
          @bundle_id
        ])

        with {:ok, _, 0} <-
               TwinProducers.capture(runtime, :uninstall, xcrun, [
                 "simctl",
                 "uninstall",
                 ctx.udid,
                 @bundle_id
               ]),
             {:ok, _, 0} <-
               TwinProducers.capture(
                 runtime,
                 :reinstall,
                 xcrun,
                 ["simctl", "install", ctx.udid, ctx.app_path],
                 deadline_ms: 120_000
               ) do
          :ok
        else
          _ -> {:blocked, :prerequisite_missing}
        end
      end

    with :ok <- reset do
      control(ctx, "POST", "/pass")
      bundle = "rb-" <> Atom.to_string(case_id)
      only = "CrosswakeShellUITests/TwinJourneyUITests/" <> method
      args = xcodebuild_args({:test, only}, Map.put(ctx, :result_bundle, bundle))
      {:ok, result} = xcodebuild(ctx, case_id, args, 900_000)

      TwinProducers.capture(runtime, :terminate_after, xcrun, [
        "simctl",
        "terminate",
        ctx.udid,
        @bundle_id
      ])

      Agent.update(ctx.store, &put_in(&1, [:cases, case_id], %{class: result.class}))
      count = attachment_count(ctx, bundle, "att-" <> Atom.to_string(case_id))
      record_stage(ctx, case_id, {:ok, result}, count)

      case {result.class, count} do
        {_, {:ok, 0}} ->
          collect_case(ctx, case_id)
          :ok

        {_, {:ok, _}} ->
          {:blocked, :capture_not_prevented}

        # A case killed at its deadline leaves no countable bundle; that is a timeout, not a
        # broken attachment check.
        {:timeout, {:unavailable, _}} ->
          {:blocked, :child_timeout}

        {_, {:unavailable, _}} ->
          {:blocked, :attachment_check_unavailable}
      end
    end
  end

  defp collect_case(ctx, case_id) do
    xcrun = ctx.tools.xcrun
    runtime = ctx.runtime
    dest = Path.join([ctx.run_root, "obs", Atom.to_string(case_id)])
    File.mkdir_p!(dest)

    with {:ok, out, 0} <-
           TwinProducers.capture(runtime, :data_container, xcrun, [
             "simctl",
             "get_app_container",
             ctx.udid,
             @bundle_id,
             "data"
           ]) do
      data = String.trim(out)

      for {_channel, file} <- TwinProducers.channel_files() do
        File.cp(Path.join([data, "Library", "Caches", file]), Path.join(dest, file))
      end

      if case_id == :c1, do: observe_after_c1(ctx, data, dest)
    end

    :ok
  end

  # Independent observations that exist only while the c1 app container is intact.
  defp observe_after_c1(ctx, data, dest) do
    runtime = ctx.runtime

    media =
      Path.join([data, "Library", "Application Support", "CrosswakeTwin", "pronunciation.aiff"])

    installed_media = ok_value(TwinProducers.file_digest(media))

    with {:ok, app_out, 0} <-
           TwinProducers.capture(runtime, :app_container, ctx.tools.xcrun, [
             "simctl",
             "get_app_container",
             ctx.udid,
             @bundle_id,
             "app"
           ]) do
      app = String.trim(app_out)

      live = %{
        installed_manifest:
          ok_value(TwinProducers.file_digest(Path.join(app, "crosswake_manifest.json"))),
        installed_activation:
          ok_value(TwinProducers.file_digest(Path.join(app, "route_activation.json"))),
        installed_media: installed_media,
        exec_after_c1: ok_value(TwinProducers.file_digest(Path.join(app, "CrosswakeShell")))
      }

      first_pid_absent = first_pid_absent?(ctx, dest)

      Agent.update(
        ctx.store,
        &(&1 |> Map.put(:live, live) |> Map.put(:first_pid_absent, first_pid_absent))
      )
    end
  end

  # Read-only /bin/ps: the first launch's process must be gone.
  defp first_pid_absent?(ctx, dest) do
    with {:ok, text} <- File.read(Path.join(dest, TwinProducers.channel_files().app_process)),
         {:ok, [first | _]} <- TwinProducers.parse_channel(:app_process, text),
         {:ok, out, _status} <-
           TwinProducers.capture(ctx.runtime, :ps, "/bin/ps", [
             "-p",
             Integer.to_string(first.value),
             "-o",
             "pid="
           ]) do
      String.trim(out) == ""
    else
      _ -> nil
    end
  end

  # ---- assemble

  defp assemble(ctx) do
    TwinFaultBoundary.finish(ctx.boundary)
    state = Agent.get(ctx.store, & &1)
    run_id = ctx.runtime.run_id

    cases =
      Map.new(@cases, fn {case_id, _method} ->
        {case_id,
         TwinProducers.read_case(Path.join([ctx.run_root, "obs", Atom.to_string(case_id)]))}
      end)

    snapshots = TwinFaultBoundary.snapshots(ctx.boundary)

    inputs = %{
      cases: cases,
      boundary: %{
        counters: TwinFaultBoundary.counters(ctx.boundary),
        epochs: Enum.map(snapshots, &elem(&1, 0))
      },
      backend: state.snapshots,
      process: %{
        first_pid_absent: Map.get(state, :first_pid_absent),
        exec_after_install: Map.get(state, :exec_after_install),
        exec_after_c1: get_in(state, [:live, :exec_after_c1]),
        installs_before_c1: state.installs
      }
    }

    live =
      state
      |> Map.get(:live, %{})
      |> Map.put(:served_js, TwinFaultBoundary.static_digest(ctx.boundary))
      |> Map.put(:backend_build, backend_build(ctx))
      |> then(fn live ->
        stable =
          case {Map.get(state, :exec_after_install), live[:exec_after_c1]} do
            {a, b} when is_binary(a) and is_binary(b) -> a == b
            _ -> nil
          end

        Map.put(live, :executable_stable, stable)
      end)

    observed = TwinProducers.observe_identities(ctx.frozen, live)

    observations =
      TwinProducers.host_adapter(inputs, run_id) ++
        TwinProducers.webview(inputs, run_id) ++
        TwinProducers.app_process(inputs, run_id) ++
        TwinProducers.fault_boundary(inputs, run_id) ++
        TwinProducers.phoenix_ecto(inputs, run_id)

    all = observations ++ TwinProducers.runner(ctx.frozen.expectations, observed, observations)
    {:ok, observed, all}
  end

  defp backend_build(ctx) do
    with {:ok, 200, body} <-
           TwinFaultBoundary.upstream_request(ctx.upstream_port, "GET", "/_e2e/twin/build"),
         {:ok, %{"data" => %{"build_sha256" => digest}}} <- Jason.decode(body) do
      digest
    else
      _ -> nil
    end
  end

  # ---- teardown

  defp finish(ctx, result) do
    state = Agent.get(ctx.store, & &1)
    runtime = ctx.runtime

    if boundary = Map.get(ctx, :boundary), do: TwinFaultBoundary.stop(boundary)
    write_stages(runtime, state.stages)
    delete_simulator(ctx, state)
    # The command still reads and records causes after the journey, so the registry and
    # origin are released by the command's own stop_all/1, not here.
    TwinRuntime.stop_children(runtime)
    if Process.alive?(ctx.store), do: Agent.stop(ctx.store)

    case cleanup(runtime.run_root) do
      :ok -> result
      {:error, :residue} -> {:blocked, :cause_not_retained}
    end
  end

  @doc """
  Writes the closed per-stage record (`crosswake.twin_run_stages/1`) next to the receipt, once,
  with mode 0600. It is diagnosis for the next repair, not evidence; the receipt stays the verdict.
  """
  @spec write_stages(TwinRuntime.t(), [map()]) :: :ok | {:error, term()}
  def write_stages(runtime, stages) do
    stages = for %{stage: stage} = entry <- stages, do: Map.put(entry, :stage, stage_name(stage))

    bytes =
      Jason.encode!(%{
        schema: "crosswake.twin_run_stages/1",
        run_id: runtime.run_id,
        stages: stages,
        not_reached:
          for({id, _} <- @cases, Atom.to_string(id) not in Enum.map(stages, & &1.stage), do: id)
      })

    path = Path.join(runtime.run_root, @stages_file)

    with {:ok, io} <- File.open(path, [:write, :exclusive, :binary]),
         :ok <- IO.binwrite(io, bytes),
         :ok <- File.close(io) do
      File.chmod(path, 0o600)
    end
  end

  defp stage_name(stage) when is_atom(stage), do: Atom.to_string(stage)

  # Only the simulator this run created, by its own UDID.
  defp delete_simulator(ctx, %{udid: udid}) do
    xcrun = System.find_executable("xcrun")

    if xcrun do
      System.cmd(xcrun, ["simctl", "shutdown", udid], stderr_to_stdout: true)
      System.cmd(xcrun, ["simctl", "delete", udid], stderr_to_stdout: true)
    end

    _ = ctx
    :ok
  end

  defp delete_simulator(_ctx, _state), do: :ok

  # ---- small helpers

  defp control(ctx, method, path),
    do: TwinFaultBoundary.upstream_request(ctx.control_port, method, path)

  defp ok_value({:ok, value}), do: value
  defp ok_value(_), do: nil
end
