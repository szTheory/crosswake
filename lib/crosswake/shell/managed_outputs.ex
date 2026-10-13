defmodule Crosswake.Shell.ManagedOutputs do
  @moduledoc false
  @metadata ".crosswake/ios_host_generation.json"
  @pending ".crosswake/ios_host_generation.pending"
  @stage ".crosswake/ios_host_generation.stage"
  @paths [
    "Fixtures/crosswake_manifest.json",
    "Fixtures/route_activation.json",
    "CrosswakeHostSettings.xcconfig"
  ]
  @max_bytes 8 * 1024 * 1024
  def paths, do: @paths

  def generated_at(root) do
    with :ok <- safe_layout(root),
         {:ok, metadata} when is_map(metadata) <- read_metadata(root),
         {:ok, bytes} <- safe_read(root, "Fixtures/crosswake_manifest.json"),
         expected when is_binary(expected) <-
           get_in(metadata, ["outputs", "Fixtures/crosswake_manifest.json"]),
         true <- digest(bytes) == expected,
         {:ok, %{"generated_at" => value}} <- Jason.decode(bytes),
         true <- is_binary(value) do
      value
    else
      _ -> nil
    end
  end

  def check(root, desired) do
    with :ok <- validate_desired(desired),
         :ok <- safe_layout(root),
         :ok <- no_pending(root),
         {:ok, metadata} <- read_metadata(root) do
      statuses =
        Map.new(@paths, fn path -> {path, classify_file(root, path, desired[path], metadata)} end)

      cond do
        Enum.any?(statuses, fn {_, v} -> v == :conflict end) ->
          error(:conflict)

        Enum.any?(statuses, fn {_, v} -> v == :unsafe end) ->
          error(:unsafe_path)

        Enum.any?(statuses, fn {_, v} -> v == :stale end) ->
          error(:stale, outputs: statuses)

        Enum.any?(statuses, fn {_, v} -> v == :missing end) ->
          error(:missing, outputs: statuses)

        true ->
          {:ok, %{status: :current, generation_id: metadata["generation_id"], outputs: statuses}}
      end
    else
      {:error, :interrupted} -> error(:interrupted)
      {:error, :unsafe_path} -> error(:unsafe_path)
      {:error, :invalid_metadata} -> error(:conflict)
    end
  end

  def diff(root, desired), do: check(root, desired)

  def preflight(root, desired) do
    case check(root, desired) do
      {:ok, _} -> :ok
      {:error, %{cause: cause}} when cause in [:missing, :stale] -> :ok
      {:error, %{cause: cause}} -> {:error, cause}
    end
  end

  def publish(root, desired, opts \\ []) do
    with :ok <- validate_desired(desired),
         :ok <- safe_layout(root),
         {:ok, prior} <- inspect_for_publish(root, desired),
         :ok <- create_private_dirs(root),
         {:ok, generation} <- stage_generation(root, desired, prior),
         :ok <- replace_outputs(root, desired, opts),
         :ok <- promote_metadata(root, desired, generation),
         :ok <- verify_desired(root, desired, generation),
         :ok <- remove_pending(root),
         :ok <- remove_stage(root) do
      :ok
    else
      {:error, cause} when cause in [:conflict, :unsafe_path, :interrupted] -> error(cause)
      {:error, reason} -> error(:write_failed, reason: safe_reason(reason))
    end
  end

  def recover(root) do
    with :ok <- safe_layout(root),
         {:ok, pending} <- read_pending(root),
         {:ok, staged} <- read_stage(root, pending),
         :ok <- current_matches_recoverable(root, staged),
         {:ok, chosen} <- recovery_set(staged),
         :ok <- restore_set(root, chosen),
         :ok <- verify_set(root, chosen),
         :ok <- remove_pending(root),
         :ok <- remove_stage(root) do
      {:ok, %{status: :recovered, generation_id: chosen["generation_id"]}}
    else
      {:error, :no_pending} -> error(:no_pending)
      {:error, :unsafe_path} -> error(:unsafe_path)
      {:error, :external_change} -> error(:conflict)
      {:error, reason} -> error(:interrupted, reason: safe_reason(reason))
    end
  end

  def guard_script(desired) do
    expected =
      Enum.map(@paths, fn p -> "  check '#{digest(desired[p])}' '#{p}'\\n" end) |> Enum.join()

    """
    #!/bin/sh
    set -eu
    project_dir="${PROJECT_DIR:?}"
    pending="$project_dir/../.crosswake/ios_host_generation.pending"
    if [ -e "$pending" ]; then echo "Crosswake iOS outputs are interrupted; run mix crosswake.gen.shell ios --recover" >&2; exit 1; fi
    if [ ! -f "$project_dir/../.crosswake/ios_host_generation.json" ]; then exit 0; fi
    check() {
      expected="$1"; relative="$2"
      actual=$(shasum -a 256 "$project_dir/../$relative" 2>/dev/null | awk '{print $1}') || return 1
      [ "$actual" = "$expected" ]
    }
    if ! (
    #{expected}  exit 0
    ); then
      echo "Crosswake iOS outputs are inconsistent; run mix crosswake.gen.shell ios --recover" >&2
      exit 1
    fi
    """
  end

  defp validate_desired(d) when is_map(d) do
    if Enum.sort(Map.keys(d)) == Enum.sort(@paths) and
         Enum.all?(d, fn {_, v} -> is_binary(v) and byte_size(v) <= @max_bytes end),
       do: :ok,
       else: {:error, :invalid_desired}
  end

  defp validate_desired(_), do: {:error, :invalid_desired}

  defp inspect_for_publish(root, d) do
    case check(root, d) do
      {:ok, _} -> {:ok, snapshot(root)}
      {:error, %{cause: cause}} when cause in [:missing, :stale] -> {:ok, snapshot(root)}
      {:error, %{cause: cause}} -> {:error, cause}
    end
  end

  defp snapshot(root) do
    case read_metadata(root) do
      {:ok, m} when is_map(m) ->
        outputs =
          Map.new(@paths, fn p ->
            case safe_read(root, p) do
              {:ok, b} -> {p, Base.encode64(b)}
              _ -> {p, nil}
            end
          end)

        %{"generation_id" => m["generation_id"], "metadata" => m, "outputs" => outputs}

      _ ->
        %{"generation_id" => nil, "metadata" => nil, "outputs" => Map.new(@paths, &{&1, nil})}
    end
  end

  defp create_private_dirs(root) do
    File.mkdir_p!(root)
    File.mkdir_p!(Path.join(root, ".crosswake"))

    case File.chmod(Path.join(root, ".crosswake"), 0o700) do
      :ok -> :ok
      _ -> {:error, :write_failed}
    end
  rescue
    _ -> {:error, :write_failed}
  end

  defp stage_generation(root, d, prior) do
    stage = Path.join(root, @stage)
    gen = desired_generation(d)
    payload = %{"generation_id" => gen, "desired" => encode_outputs(d), "prior" => prior}

    with :ok <- make_stage(stage),
         :ok <- write_private(Path.join(stage, "snapshot.json"), Jason.encode!(payload)),
         :ok <-
           write_private(
             Path.join(root, @pending),
             Jason.encode!(%{"generation_id" => gen, "stage" => @stage})
           ) do
      {:ok, gen}
    end
  end

  defp make_stage(path) do
    case File.lstat(path) do
      {:error, :enoent} -> with :ok <- File.mkdir(path), :ok <- File.chmod(path, 0o700), do: :ok
      _ -> {:error, :interrupted}
    end
  end

  defp replace_outputs(root, d, opts) do
    @paths
    |> Enum.map(fn path -> {path, Map.fetch!(d, path)} end)
    |> Enum.reduce_while(0, fn {p, b}, n ->
      case atomic_replace(root, p, b) do
        :ok ->
          if n == 0 and Keyword.get(opts, :interrupt_after_first, false),
            do: {:halt, {:error, :interrupted}},
            else: {:cont, n + 1}

        e ->
          {:halt, e}
      end
    end)
    |> case do
      {:error, _} = e -> e
      _ -> :ok
    end
  end

  defp atomic_replace(root, p, bytes) do
    dest = Path.join(root, p)
    parent = Path.dirname(dest)
    File.mkdir_p!(parent)
    tmp = Path.join(parent, ".crosswake-write-#{System.unique_integer([:positive])}")

    case write_private(tmp, bytes) do
      :ok ->
        case File.rename(tmp, dest) do
          :ok ->
            :ok

          _ ->
            File.rm(tmp)
            {:error, :write_failed}
        end

      _ ->
        {:error, :write_failed}
    end
  rescue
    _ -> {:error, :write_failed}
  end

  defp promote_metadata(root, d, g) do
    m = metadata_for(d, g)
    atomic_replace(root, @metadata, Jason.encode!(m))
  end

  defp verify_desired(root, d, g) do
    with {:ok, m} <- read_metadata(root),
         true <- m["generation_id"] == g,
         true <- Enum.all?(@paths, fn p -> safe_read(root, p) == {:ok, d[p]} end),
         do: :ok,
         else: (_ -> {:error, :interrupted})
  end

  defp read_metadata(root) do
    case safe_read(root, @metadata) do
      {:ok, b} ->
        case Jason.decode(b) do
          {:ok, %{"version" => 1, "generation_id" => id, "outputs" => o} = m}
          when is_binary(id) and is_map(o) ->
            if valid_generation?(id) and Enum.sort(Map.keys(o)) == Enum.sort(@paths) and
                 Enum.all?(o, fn {_, v} ->
                   is_binary(v) and Regex.match?(~r/\A[0-9a-f]{64}\z/, v)
                 end), do: {:ok, m}, else: {:error, :invalid_metadata}

          _ ->
            {:error, :invalid_metadata}
        end

      {:error, :missing} ->
        {:ok, nil}

      e ->
        e
    end
  end

  defp classify_file(root, p, d, m) do
    case safe_read(root, p) do
      {:error, :missing} ->
        :missing

      {:error, :unsafe} ->
        :unsafe

      {:ok, _} when is_nil(m) ->
        :conflict

      {:ok, b} ->
        recognized = get_in(m, ["outputs", p])

        cond do
          is_nil(recognized) or digest(b) != recognized -> :conflict
          digest(b) == digest(d) -> :current
          true -> :stale
        end
    end
  end

  defp safe_layout(root) when is_binary(root) do
    r = Path.expand(root)

    with :ok <- safe_ancestors(r) do
      case File.lstat(r) do
        {:error, :enoent} ->
          :ok

        {:ok, %{type: :directory}} ->
          Enum.reduce_while([@metadata, @pending, @stage] ++ @paths, :ok, fn p, :ok ->
            case safe_components(r, Path.dirname(p)) do
              :ok ->
                case File.lstat(Path.join(r, p)) do
                  {:ok, %{type: :regular}} -> {:cont, :ok}
                  {:ok, %{type: :directory}} when p == @stage -> {:cont, :ok}
                  {:error, :enoent} -> {:cont, :ok}
                  _ -> {:halt, {:error, :unsafe_path}}
                end

              _ ->
                {:halt, {:error, :unsafe_path}}
            end
          end)

        _ ->
          {:error, :unsafe_path}
      end
    end
  end

  defp safe_layout(_), do: {:error, :unsafe_path}

  defp safe_ancestors(path) do
    path
    |> Path.split()
    |> Enum.reject(&(&1 == "/"))
    |> Enum.reduce_while("/", fn part, parent ->
      candidate = Path.join(parent, part)

      case File.lstat(candidate) do
        {:ok, %{type: :directory}} ->
          {:cont, candidate}

        {:ok, %{type: :symlink}} ->
          if trusted_temp_alias?(candidate, parent),
            do: {:cont, candidate},
            else: {:halt, {:error, :unsafe_path}}

        {:error, :enoent} ->
          {:halt, :missing}

        _ ->
          {:halt, {:error, :unsafe_path}}
      end
    end)
    |> case do
      :missing -> :ok
      {:error, :unsafe_path} = error -> error
      _ -> :ok
    end
  end

  # macOS exposes these stable logical aliases for private temporary roots.
  # Permit only the two known one-way aliases; arbitrary links stay rejected.
  defp trusted_temp_alias?(candidate, parent) when candidate in ["/tmp", "/var"] do
    expected = if candidate == "/tmp", do: "/private/tmp", else: "/private/var"

    case File.read_link(candidate) do
      {:ok, target} -> Path.expand(target, parent) == expected
      _ -> false
    end
  end

  defp trusted_temp_alias?(_, _), do: false

  defp safe_components(root, rel) do
    rel
    |> Path.split()
    |> Enum.reduce_while(root, fn part, parent ->
      case File.lstat(Path.join(parent, part)) do
        {:ok, %{type: :directory}} -> {:cont, Path.join(parent, part)}
        {:error, :enoent} -> {:halt, :missing}
        _ -> {:halt, :unsafe}
      end
    end)
    |> case do
      :missing -> :ok
      :unsafe -> {:error, :unsafe_path}
      _ -> :ok
    end
  end

  defp safe_read(root, p) do
    path = Path.join(root, p)

    case File.lstat(path) do
      {:ok, %{type: :regular}} ->
        case File.read(path) do
          {:ok, b} when byte_size(b) <= @max_bytes -> {:ok, b}
          _ -> {:error, :unsafe}
        end

      {:error, :enoent} ->
        {:error, :missing}

      _ ->
        {:error, :unsafe}
    end
  rescue
    _ -> {:error, :unsafe}
  end

  defp no_pending(root) do
    case safe_read(root, @pending) do
      {:error, :missing} -> :ok
      {:ok, _} -> {:error, :interrupted}
      _ -> {:error, :unsafe_path}
    end
  end

  defp read_pending(root) do
    case safe_read(root, @pending) do
      {:error, :missing} ->
        {:error, :no_pending}

      {:ok, b} ->
        with {:ok, %{"generation_id" => id, "stage" => @stage} = p} <- Jason.decode(b),
             true <- valid_generation?(id),
             do: {:ok, p},
             else: (_ -> {:error, :interrupted})

      _ ->
        {:error, :interrupted}
    end
  end

  defp read_stage(root, pending) do
    with {:ok, b} <- safe_read(root, Path.join(@stage, "snapshot.json")),
         {:ok, %{"generation_id" => id, "desired" => enc, "prior" => prior}} <- Jason.decode(b),
         true <- id == pending["generation_id"],
         {:ok, d} <- decode_outputs(enc),
         true <- desired_generation(d) == id,
         do: {:ok, %{"generation_id" => id, "desired" => d, "prior" => prior}},
         else: (_ -> {:error, :interrupted})
  end

  defp current_matches_recoverable(root, s) do
    prior = s["prior"]
    desired = s["desired"]

    Enum.reduce_while(@paths, :ok, fn p, :ok ->
      old = decode_optional((prior["outputs"] || %{})[p])

      case safe_read(root, p) do
        {:error, :missing} ->
          if is_nil(old), do: {:cont, :ok}, else: {:halt, {:error, :external_change}}

        {:ok, b} ->
          if b == desired[p] or b == old,
            do: {:cont, :ok},
            else: {:halt, {:error, :external_change}}

        _ ->
          {:halt, {:error, :external_change}}
      end
    end)
  end

  defp recovery_set(s) do
    p = s["prior"]

    if is_map(p["metadata"]) and
         Enum.all?(@paths, &is_binary(decode_optional((p["outputs"] || %{})[&1]))) do
      outs = Map.new(@paths, &{&1, decode_optional(p["outputs"][&1])})

      {:ok,
       %{
         "generation_id" => p["metadata"]["generation_id"],
         "outputs" => outs,
         "metadata" => p["metadata"]
       }}
    else
      d = s["desired"]

      {:ok,
       %{
         "generation_id" => s["generation_id"],
         "outputs" => d,
         "metadata" => metadata_for(d, s["generation_id"])
       }}
    end
  end

  defp restore_set(root, s) do
    Enum.reduce_while(@paths, :ok, fn p, :ok ->
      case atomic_replace(root, p, s["outputs"][p]) do
        :ok -> {:cont, :ok}
        e -> {:halt, e}
      end
    end)
    |> case do
      :ok -> atomic_replace(root, @metadata, Jason.encode!(s["metadata"]))
      e -> e
    end
  end

  defp verify_set(root, s) do
    with {:ok, m} <- read_metadata(root),
         true <- m == s["metadata"],
         true <- Enum.all?(@paths, fn p -> safe_read(root, p) == {:ok, s["outputs"][p]} end),
         do: :ok,
         else: (_ -> {:error, :interrupted})
  end

  defp metadata_for(d, g),
    do: %{
      "version" => 1,
      "generation_id" => g,
      "outputs" => Map.new(@paths, &{&1, digest(d[&1])})
    }

  defp encode_outputs(d), do: Map.new(d, fn {p, b} -> {p, Base.encode64(b)} end)

  defp decode_outputs(e) when is_map(e) and map_size(e) == 3 do
    Enum.reduce_while(e, {:ok, %{}}, fn {p, v}, {:ok, a} ->
      case Base.decode64(v) do
        {:ok, b} when byte_size(b) <= @max_bytes -> {:cont, {:ok, Map.put(a, p, b)}}
        _ -> {:halt, {:error, :interrupted}}
      end
    end)
  end

  defp decode_outputs(_), do: {:error, :interrupted}
  defp decode_optional(nil), do: nil

  defp decode_optional(b) when is_binary(b) do
    case Base.decode64(b) do
      {:ok, v} -> v
      _ -> :invalid
    end
  end

  defp decode_optional(_), do: :invalid

  defp desired_generation(d),
    do: Enum.map(@paths, fn p -> [p, <<0>>, d[p], <<0>>] end) |> IO.iodata_to_binary() |> digest()

  defp digest(b), do: :crypto.hash(:sha256, b) |> Base.encode16(case: :lower)
  defp valid_generation?(v), do: is_binary(v) and Regex.match?(~r/\A[0-9a-f]{64}\z/, v)

  defp write_private(p, b) do
    with :ok <- File.write(p, b, [:binary]), :ok <- File.chmod(p, 0o600), do: :ok
  rescue
    _ -> {:error, :write_failed}
  end

  defp remove_pending(root) do
    case File.rm(Path.join(root, @pending)) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      _ -> {:error, :interrupted}
    end
  end

  defp remove_stage(root) do
    case File.rm_rf(Path.join(root, @stage)) do
      {:ok, _} -> :ok
      _ -> {:error, :interrupted}
    end
  end

  defp safe_reason(reason)
       when reason in [
              :invalid_desired,
              :write_failed,
              :interrupted,
              :no_pending,
              :external_change,
              :unsafe_path,
              :missing
            ],
       do: reason

  defp safe_reason(_), do: :filesystem

  defp error(cause, details \\ []) do
    repair =
      case cause do
        :missing ->
          "run mix crosswake.gen.shell ios to create the managed iOS outputs"

        :stale ->
          "run mix crosswake.gen.shell ios to refresh recognized iOS outputs"

        :conflict ->
          "review the host-owned file, then restore recognized bytes or migrate project settings explicitly"

        :unsafe_path ->
          "remove the symlink or non-regular managed destination, then rerun the iOS task"

        :interrupted ->
          "run mix crosswake.gen.shell ios --recover after reviewing the staged generation"

        :no_pending ->
          "no interrupted generation is waiting for recovery"

        _ ->
          "inspect the host configuration and rerun the iOS task"
      end

    {:error, Map.merge(%{cause: cause, repair: repair}, Map.new(details))}
  end
end
