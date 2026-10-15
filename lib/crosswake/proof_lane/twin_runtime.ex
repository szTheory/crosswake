defmodule Crosswake.ProofLane.TwinRuntime do
  @moduledoc """
  Bounded, owned runtime resources for one twin run.

  `prepare/1` validates a prepared candidate record, creates or verifies a
  private run root, resolves a fresh SQLite path inside it, and acquires an
  exclusive listening socket on the prepared candidate's exact loopback origin.
  That listener stays open for the whole run so no other process can bind the
  origin between preflight and use; it is handed (never released) to the fault
  boundary. If the port is occupied the outcome is blocked with a concrete
  preparation action; the occupant is never connected to, signalled or killed.

  Children start from executable-plus-argument lists under explicit deadlines.
  Only processes this module started are tracked, terminated and reaped, by
  their own OS process handles. Nothing is looked up by port.
  """

  import Bitwise

  alias Crosswake.ProofLane.TwinReceipt

  @receipt_name "receipt.json"
  @term_grace_ms 2_000
  @default_run_deadline_ms 3_600_000
  @flag_name ~r/\ACROSSWAKE_TWIN_[A-Z0-9_]+\z/

  @enforce_keys [:run_id, :run_root, :database_path, :origin, :origin_port, :registry]
  defstruct [
    :run_id,
    :run_root,
    :database_path,
    :origin,
    :origin_port,
    :origin_listener,
    :candidate_path,
    :candidate_head,
    :candidate_tree,
    :resource_digests,
    :fixture_digests,
    :registry,
    :run_deadline_at
  ]

  @type t :: %__MODULE__{}
  @type failure :: %{cause: atom(), action: String.t()}

  @type checked :: %{
          root: %{path: String.t(), create?: boolean()},
          record: map(),
          db: String.t(),
          port: pos_integer(),
          run_deadline_ms: pos_integer() | nil
        }

  @doc """
  Checks a run without side effects: no directory is created, no process is
  started and no socket is kept open. Options are those of `prepare/1` plus
  `:current_uid` (test seam for the run-root owner check).

  Checks run in order: run root (exists, is a real directory not a symlink, mode
  0700-style private, and owned by the current user; the owner check is new
  behaviour of the real run), not reused, candidate record, outside the
  candidate, database path, origin port, and origin bindable (bound and
  released at once, so it only says the port is free at this moment).
  """
  @spec check(keyword()) :: {:ok, checked()} | {:error, failure()}
  def check(opts) when is_list(opts) do
    with {:ok, root} <- run_root_check(opts[:run_root], opts),
         :ok <- not_reused(root),
         {:ok, record} <- candidate_record(opts[:candidate]),
         :ok <- outside_candidate(root.path, record.candidate_path),
         {:ok, db} <- database_path(root, opts[:database_path]),
         {:ok, port} <- origin_port(record.origin),
         :ok <- origin_bindable(port) do
      {:ok,
       %{
         root: root,
         record: record,
         db: db,
         port: port,
         run_deadline_ms: opts[:run_deadline_ms]
       }}
    end
  end

  @doc """
  Commits a checked run: the only code that creates a run root (when none was
  given), acquires and holds the origin listener, and starts the run registry.
  """
  @spec commit(checked()) :: {:ok, t()} | {:error, failure()}
  def commit(%{root: root, record: record, db: db, port: port} = checked) do
    with :ok <- maybe_create_root(root),
         {:ok, listener} <- acquire_origin_or_cleanup(root, port) do
      {:ok, registry} = Agent.start(fn -> %{children: %{}, first_failure: nil} end)
      deadline = now_ms() + (checked.run_deadline_ms || @default_run_deadline_ms)

      {:ok,
       %__MODULE__{
         run_id: "twin-" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower),
         run_root: root.path,
         database_path: db,
         origin: record.origin,
         origin_port: port,
         origin_listener: listener,
         candidate_path: record.candidate_path,
         candidate_head: record.head,
         candidate_tree: record.tree,
         resource_digests: record.resource_digests,
         fixture_digests: record.fixture_digests,
         registry: registry,
         run_deadline_at: deadline
       }}
    end
  end

  @doc """
  Prepares a run: `check/1` then `commit/1`. Options: `:candidate` (path to the prepared candidate record,
  required), `:run_root` (existing private directory; created under the system
  temp dir when omitted), `:database_path` (must resolve inside the run root to
  a path that does not exist) and `:run_deadline_ms`.

  The candidate record is a private (mode 0600) JSON file with `candidate_path`,
  `expected_head`, `expected_tree`, `origin` (the declared primary loopback
  origin), `resource_digests` and `fixture_digests`.
  """
  @spec prepare(keyword()) :: {:ok, t()} | {:error, failure()}
  def prepare(opts) when is_list(opts) do
    with {:ok, checked} <- check(opts), do: commit(checked)
  end

  @doc "Environment for the owned Phoenix child (test-gated flags only, by name)."
  @spec env_for_backend(t(), pos_integer(), keyword()) :: [{String.t(), String.t()}]
  def env_for_backend(%__MODULE__{} = runtime, port, flags \\ []) when is_integer(port) do
    gated =
      for {name, value} <- flags, Regex.match?(@flag_name, name), do: {name, to_string(value)}

    [
      {"MIX_ENV", "test"},
      {"PORT", Integer.to_string(port)},
      {"DATABASE_PATH", runtime.database_path},
      {"PHX_SERVER", "true"}
    ] ++ gated
  end

  @doc """
  Starts one tracked child. `spec` has `:path` (executable), `:args` (list),
  `:env` (list of string pairs), optional `:cd` and `:deadline_ms`. The child
  becomes its own process group leader so termination reaches only its own
  descendants.
  """
  @spec start_child(t(), atom() | String.t(), map()) :: {:ok, map()} | {:error, failure()}
  def start_child(%__MODULE__{} = runtime, name, %{path: path, args: args} = spec)
      when is_binary(path) and is_list(args) do
    env =
      for {k, v} <- Map.get(spec, :env, []), do: {String.to_charlist(k), String.to_charlist(v)}

    {exe, exe_args} = group_leader_wrapper(path, args)

    port_opts =
      [:binary, :exit_status, :use_stdio, :stderr_to_stdout, args: exe_args, env: env] ++
        if(spec[:cd], do: [cd: String.to_charlist(spec.cd)], else: [])

    try do
      port = Port.open({:spawn_executable, String.to_charlist(exe)}, port_opts)
      {:os_pid, os_pid} = Port.info(port, :os_pid)
      deadline = min(now_ms() + Map.get(spec, :deadline_ms, 60_000), runtime.run_deadline_at)
      child = %{name: name, port: port, os_pid: os_pid, deadline_at: deadline}
      Agent.update(runtime.registry, &put_in(&1, [:children, name], child))
      {:ok, child}
    rescue
      _ ->
        {:error,
         failure(
           :prerequisite_missing,
           "Install or restore the missing executable and run again with a new run root"
         )}
    end
  end

  @doc """
  Waits for a child's exit or its deadline. On deadline the child is
  terminated and reaped by its own handle and `child_timeout` is recorded as
  the first failure (if none was recorded before).
  """
  @spec await_exit(t(), map()) :: {:ok, integer()} | {:error, :child_timeout}
  def await_exit(%__MODULE__{} = runtime, %{port: port, deadline_at: deadline} = child) do
    wait = max(deadline - now_ms(), 0)

    receive do
      {^port, {:exit_status, status}} ->
        mark_exited(runtime, child.name)
        {:ok, status}

      {^port, {:data, _}} ->
        await_exit(runtime, child)
    after
      wait ->
        record_failure(runtime, :child_timeout)
        terminate(runtime, child)
        {:error, :child_timeout}
    end
  end

  @doc "First recorded failure cause for this run, or nil."
  @spec first_failure(t()) :: atom() | nil
  def first_failure(%__MODULE__{registry: registry}) do
    if Process.alive?(registry), do: Agent.get(registry, & &1.first_failure), else: nil
  end

  # A registry already released by stop_all/1 keeps no further causes; the caller still
  # carries the cause into the receipt, so the first written result is never lost.
  @spec record_failure(t(), atom()) :: :ok
  def record_failure(%__MODULE__{registry: registry}, cause) do
    if Process.alive?(registry) do
      Agent.update(registry, fn state ->
        %{state | first_failure: state.first_failure || TwinReceipt.safe_cause(cause)}
      end)
    else
      :ok
    end
  end

  @doc """
  Terminates and reaps every tracked child and verifies each is gone, keeping the run
  registry so the first failure stays readable until stop_all/1 releases it.
  """
  @spec stop_children(t()) :: :ok | {:error, :child_still_alive}
  def stop_children(%__MODULE__{registry: registry} = runtime) do
    children =
      if Process.alive?(registry), do: Agent.get(registry, &Map.values(&1.children)), else: []

    results = Enum.map(children, &terminate(runtime, &1))
    if Enum.all?(results, &(&1 == :ok)), do: :ok, else: {:error, :child_still_alive}
  end

  @doc "Terminates and reaps every tracked child, verifies each is gone, and closes the origin."
  @spec stop_all(t()) :: :ok | {:error, :child_still_alive}
  def stop_all(%__MODULE__{registry: registry} = runtime) do
    result = stop_children(runtime)
    if runtime.origin_listener, do: :gen_tcp.close(runtime.origin_listener)
    if Process.alive?(registry), do: Agent.stop(registry)
    result
  end

  @doc "Whether the given OS pid (or its process group) is still present."
  @spec alive?(pos_integer()) :: boolean()
  def alive?(os_pid) when is_integer(os_pid) do
    signal_zero(Integer.to_string(os_pid)) or signal_zero("-" <> Integer.to_string(os_pid))
  end

  @doc "Whether the run root already holds a receipt."
  @spec receipt_name() :: String.t()
  def receipt_name, do: @receipt_name

  # ------------------------------------------------------------------- internals

  defp terminate(%__MODULE__{} = runtime, %{port: port, os_pid: os_pid} = child) do
    if alive?(os_pid), do: signal_group(os_pid, "TERM")
    drain(port, @term_grace_ms)

    if alive?(os_pid) do
      signal_group(os_pid, "KILL")
      drain(port, @term_grace_ms)
    end

    if Port.info(port) != nil, do: Port.close(port)
    mark_exited(runtime, child.name)
    if alive?(os_pid), do: :still_alive, else: :ok
  end

  defp drain(port, grace_ms) do
    deadline = now_ms() + grace_ms
    do_drain(port, deadline)
  end

  defp do_drain(port, deadline) do
    wait = max(deadline - now_ms(), 0)

    receive do
      {^port, {:exit_status, _}} -> :ok
      {^port, {:data, _}} -> do_drain(port, deadline)
    after
      wait -> :timeout
    end
  end

  defp mark_exited(%__MODULE__{registry: registry}, name) do
    if Process.alive?(registry),
      do: Agent.update(registry, &update_in(&1, [:children], fn c -> Map.delete(c, name) end))
  end

  defp signal_group(os_pid, signal) do
    case System.find_executable("kill") do
      nil ->
        :error

      kill ->
        System.cmd(kill, ["-s", signal, "--", "-" <> Integer.to_string(os_pid)],
          stderr_to_stdout: true
        )
    end
  end

  defp signal_zero(target) do
    case System.find_executable("kill") do
      nil ->
        false

      kill ->
        {_out, status} = System.cmd(kill, ["-s", "0", "--", target], stderr_to_stdout: true)
        status == 0
    end
  end

  # Make the child its own process group leader (perl setpgrp then exec keeps the pid).
  defp group_leader_wrapper(path, args) do
    case System.find_executable("perl") do
      nil ->
        {path, args}

      perl ->
        {perl, ["-e", "setpgrp(0,0); exec { $ARGV[0] } @ARGV", "--", path | args]}
    end
  end

  defp run_root_check(nil, _opts) do
    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-twin-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)
      )

    {:ok, %{path: path, create?: true}}
  end

  defp run_root_check(path, opts) when is_binary(path) do
    expanded = Path.expand(path)

    with {:ok, %{type: :directory, mode: mode, uid: uid}} when (mode &&& 0o077) == 0 <-
           File.lstat(expanded),
         {:ok, current} <- current_uid(opts),
         true <- uid == current do
      {:ok, %{path: expanded, create?: false}}
    else
      _ ->
        {:error,
         failure(
           :prerequisite_missing,
           "Create a private run root directory (mode 0700) and run again with it"
         )}
    end
  end

  defp run_root_check(_, _opts),
    do:
      {:error, failure(:prerequisite_missing, "Pass a private run root directory and run again")}

  defp current_uid(opts) do
    case Keyword.fetch(opts, :current_uid) do
      {:ok, uid} when is_integer(uid) and uid >= 0 ->
        {:ok, uid}

      {:ok, _} ->
        :error

      :error ->
        try do
          {out, 0} =
            System.cmd(System.find_executable("id") || "/usr/bin/id", ["-u"],
              stderr_to_stdout: true
            )

          case Integer.parse(String.trim(out)) do
            {uid, ""} when uid >= 0 -> {:ok, uid}
            _ -> :error
          end
        rescue
          _ in [ErlangError, ArgumentError, MatchError] -> :error
        end
    end
  end

  defp maybe_create_root(%{create?: false}), do: :ok

  # WR-04 (D-15): only a root this call created is ever removed. An existing path (the
  # predictable temp name may already exist or be planted) is left untouched.
  defp maybe_create_root(%{path: path}) do
    case File.mkdir(path) do
      :ok ->
        case File.chmod(path, 0o700) do
          :ok ->
            :ok

          _ ->
            File.rm_rf(path)
            create_failure()
        end

      _ ->
        create_failure()
    end
  end

  defp create_failure do
    {:error,
     failure(:prerequisite_missing, "Make the system temp directory writable and run again")}
  end

  defp acquire_origin_or_cleanup(root, port) do
    case acquire_origin(port) do
      {:ok, _} = ok ->
        ok

      error ->
        if root.create?, do: File.rm_rf(root.path)
        error
    end
  end

  defp not_reused(%{create?: true}), do: :ok

  defp not_reused(%{path: root}) do
    case File.lstat(Path.join(root, @receipt_name)) do
      {:error, :enoent} ->
        :ok

      _ ->
        {:error,
         failure(:run_root_reused, "Start a new run root; a finished run is never overwritten")}
    end
  end

  # Run output must never land inside the candidate tree (it would dirty it).
  # Compared by device and inode over the run root and every ancestor, so a
  # symlink alias (/tmp vs /private/tmp) cannot hide containment and a sibling
  # sharing only a name prefix is not mistaken for it.
  defp outside_candidate(root, candidate_path) do
    case File.stat(candidate_path) do
      {:ok, %{major_device: dev, inode: ino}} ->
        if inside?(root, {dev, ino}) do
          {:error,
           failure(
             :prerequisite_missing,
             "Use a run root outside the candidate tree and run again"
           )}
        else
          :ok
        end

      _ ->
        {:error,
         failure(
           :prerequisite_missing,
           "Use a prepared candidate directory that exists and run again"
         )}
    end
  end

  defp inside?(path, identity) do
    same =
      case File.stat(path) do
        {:ok, %{major_device: dev, inode: ino}} -> {dev, ino} == identity
        _ -> false
      end

    parent = Path.dirname(path)
    same or (parent != path and inside?(parent, identity))
  end

  defp candidate_record(path) when is_binary(path) do
    expanded = Path.expand(path)

    with {:ok, %{type: :regular, mode: mode}} when (mode &&& 0o077) == 0 <- File.lstat(expanded),
         {:ok, bytes} <- File.read(expanded),
         {:ok, %{} = raw} <- Jason.decode(bytes),
         {:ok, record} <- candidate_fields(raw) do
      {:ok, record}
    else
      _ ->
        {:error,
         failure(
           :prerequisite_missing,
           "Prepare the candidate record (private file with candidate path, head, tree and origin) and run again"
         )}
    end
  end

  defp candidate_record(_),
    do:
      {:error,
       failure(:prerequisite_missing, "Pass the prepared candidate record with --candidate")}

  defp candidate_fields(%{
         "candidate_path" => candidate_path,
         "expected_head" => head,
         "expected_tree" => tree,
         "origin" => origin,
         "resource_digests" => resources,
         "fixture_digests" => fixtures
       })
       when is_binary(candidate_path) and is_binary(origin) and is_list(resources) and
              is_list(fixtures) do
    if File.dir?(candidate_path) and Regex.match?(~r/\A[0-9a-f]{40}\z/, head) and
         Regex.match?(~r/\A[0-9a-f]{40}\z/, tree) do
      {:ok,
       %{
         candidate_path: candidate_path,
         head: head,
         tree: tree,
         origin: origin,
         resource_digests: resources,
         fixture_digests: fixtures
       }}
    else
      :error
    end
  end

  defp candidate_fields(_), do: :error

  defp database_path(%{create?: true, path: root}, nil),
    do: {:ok, Path.join(root, "twin.sqlite3")}

  defp database_path(%{create?: true}, _), do: {:error, db_failure()}

  defp database_path(%{path: root} = r, nil),
    do: database_path(r, Path.join(root, "twin.sqlite3"))

  defp database_path(%{path: root}, path) when is_binary(path) do
    expanded = Path.expand(path)

    cond do
      not String.starts_with?(expanded, root <> "/") ->
        {:error, db_failure()}

      File.exists?(expanded) or match?({:ok, _}, File.lstat(expanded)) ->
        {:error, db_failure()}

      not match?({:ok, %{type: :directory}}, File.lstat(Path.dirname(expanded))) ->
        {:error, db_failure()}

      true ->
        {:ok, expanded}
    end
  end

  defp database_path(_, _), do: {:error, db_failure()}

  defp db_failure,
    do:
      failure(
        :database_path_rejected,
        "Use a database path that does not exist yet inside the run root and run again"
      )

  defp origin_port(origin) do
    case URI.parse(origin) do
      %URI{
        scheme: "http",
        host: "127.0.0.1",
        port: port,
        path: path,
        query: nil,
        fragment: nil,
        userinfo: nil
      }
      when is_integer(port) and port in 1..65_535 and path in [nil, "", "/"] ->
        {:ok, port}

      _ ->
        {:error,
         failure(
           :prerequisite_missing,
           "Declare a primary origin of the form http://127.0.0.1:<port> in the prepared candidate and run again"
         )}
    end
  end

  defp origin_bindable(port) do
    case acquire_origin(port) do
      {:ok, listener} ->
        try do
          :ok
        after
          :gen_tcp.close(listener)
        end

      error ->
        error
    end
  end

  defp acquire_origin(port) do
    case :gen_tcp.listen(port, [
           :binary,
           ip: {127, 0, 0, 1},
           reuseaddr: false,
           active: false,
           packet: :raw
         ]) do
      {:ok, listener} ->
        {:ok, listener}

      {:error, :eaddrinuse} ->
        {:error,
         failure(
           :origin_port_occupied,
           "Free 127.0.0.1:#{port} (another process is listening on it), then run again with a new run root"
         )}

      {:error, _} ->
        {:error, failure(:prerequisite_missing, "Make 127.0.0.1:#{port} bindable and run again")}
    end
  end

  defp failure(cause, action), do: %{cause: cause, action: action}
  defp now_ms, do: System.monotonic_time(:millisecond)
end
