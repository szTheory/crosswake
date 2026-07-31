defmodule Crosswake.ProofLane.Evidence do
  @moduledoc """
  Builds the deliberately small, privacy-safe proof-lane evidence artifact.

  Evidence is an allowlist contract, not a generic diagnostic envelope.  The
  same final-byte scanner is used by hashing, read-only checking, and promotion.
  """

  @schema_keys [
    :schema_version,
    :crosswake_version,
    :template_version,
    :commit_ref,
    :route_id,
    :assertion_ids,
    :status,
    :outcome,
    :captured_at,
    :retention_label,
    :device_class,
    :approved_hashes
  ]
  @outcomes [:passed, :blocked, :unavailable]
  @retention_labels [:brief, :ephemeral]
  @device_classes [:ios, :simulator, :unknown]
  @artifact_name "proof-lane-evidence.json"
  @approved_kinds [:evidence_json]
  @assertion_ids ~w(browser_offline_island shell_boot auth_continuity relaunch_persistence replay_prerequisite pack_audio_prerequisite)

  @sensitive_terms ~w(
    answer selected payload account customer credential password secret token transcript media
    archive endpoint device_id screenshot trace console log raw_output xcresult
  )

  defmodule Error do
    @moduledoc false
    @enforce_keys [:rule_id, :path, :remediation]
    defstruct [:rule_id, :path, :remediation]
  end

  @enforce_keys @schema_keys
  defstruct @schema_keys

  @type t :: %__MODULE__{}
  @type result(value) :: {:ok, value} | {:error, Error.t()}

  @spec build(map()) :: result(t())
  def build(input) when is_map(input) do
    with :ok <- atom_keys(input),
         :ok <- exact_keys(input),
         :ok <- no_sensitive_value(input),
         {:ok, hashes} <- source_hashes(input[:approved_hashes]) do
      validate_fields(Map.put(input, :approved_hashes, hashes))
    end
  end

  def build(_), do: error("PL-EVIDENCE-INPUT", "input", "supply the closed evidence map")

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = evidence) do
    %{
      "schema_version" => evidence.schema_version,
      "crosswake_version" => evidence.crosswake_version,
      "template_version" => evidence.template_version,
      "commit_ref" => evidence.commit_ref,
      "route_id" => evidence.route_id,
      "assertion_ids" => evidence.assertion_ids,
      "status" => Atom.to_string(evidence.status),
      "outcome" => Atom.to_string(evidence.outcome),
      "captured_at" => evidence.captured_at,
      "retention_label" => Atom.to_string(evidence.retention_label),
      "device_class" => Atom.to_string(evidence.device_class),
      "approved_hashes" => Enum.map(evidence.approved_hashes, &hash_to_map/1)
    }
  end

  @spec approved_hash(atom(), binary()) :: result(String.t())
  def approved_hash(kind, bytes) when kind in @approved_kinds and is_binary(bytes) do
    with :ok <- scan_bytes(bytes, @artifact_name) do
      {:ok, :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)}
    end
  end

  def approved_hash(_, _),
    do: error("PL-EVIDENCE-HASH-KIND", "artifact", "use an approved sanitized artifact")

  @spec check(Path.t()) :: :ok | {:error, Error.t()}
  def check(path) when is_binary(path) do
    with :ok <- scan_stage(path),
         {:ok, evidence} <- read_evidence(path),
         :ok <- require_sources(evidence.approved_hashes) do
      :ok
    end
  end

  def check(_), do: error("PL-EVIDENCE-PATH", "artifact", "use a safe evidence directory")

  @spec check(Path.t(), list()) :: :ok | {:error, Error.t()}
  def check(path, sources) when is_binary(path) and is_list(sources) do
    with :ok <- scan_stage(path),
         {:ok, evidence} <- read_evidence(path),
         :ok <- verify_sources(evidence.approved_hashes, sources) do
      :ok
    end
  end

  def check(_, _),
    do: error("PL-EVIDENCE-HASH-SOURCE", "approved_hashes", "supply approved canonical sources")

  @spec scan_stage(Path.t()) :: :ok | {:error, Error.t()}
  def scan_stage(stage) when is_binary(stage) do
    with {:ok, entries} <- enumerate(stage),
         :ok <- ensure_only_evidence(entries),
         :ok <- scan_file(Path.join(stage, @artifact_name)) do
      :ok
    end
  end

  def scan_stage(_), do: error("PL-EVIDENCE-PATH", "artifact", "use a safe evidence directory")

  @spec promote(map() | t(), Path.t()) :: :ok | {:error, Error.t()}
  def promote(candidate, destination), do: promote(candidate, destination, [])

  @spec promote(map() | t(), Path.t(), keyword()) :: :ok | {:error, Error.t()}
  def promote(candidate, destination, opts) when is_binary(destination) and is_list(opts) do
    with {:ok, evidence} <- normalize(candidate),
         :ok <- safe_destination(destination) do
      stage = destination <> ".stage-" <> Integer.to_string(System.unique_integer([:positive]))

      try do
        with :ok <- File.mkdir(stage),
             :ok <- write_evidence(stage, evidence),
             :ok <- scan_stage(stage),
             :ok <- run_hook(Keyword.get(opts, :before_promote)),
             :ok <- Crosswake.ProofLane.NativePromotion.rename_noreplace(stage, destination) do
          :ok
        else
          {:error, %Error{} = error} ->
            {:error, error}

          {:error, _} ->
            error("PL-EVIDENCE-PROMOTE", "artifact", "inspect the safe evidence inputs")
        end
      after
        # Only our unique sibling stage is removable; a winner is never touched.
        File.rm_rf(stage)
      end
    end
  end

  def promote(_, _, _), do: error("PL-EVIDENCE-PATH", "artifact", "use a safe evidence directory")

  defp normalize(%__MODULE__{} = evidence), do: {:ok, evidence}
  defp normalize(input), do: build(input)

  defp atom_keys(map) do
    if Enum.all?(Map.keys(map), &is_atom/1),
      do: :ok,
      else: error("PL-EVIDENCE-KEY", "input", "use declared evidence keys")
  end

  defp exact_keys(map) do
    if Map.keys(map) |> MapSet.new() == MapSet.new(@schema_keys),
      do: :ok,
      else: error("PL-EVIDENCE-KEY", "input", "use only declared evidence keys")
  end

  defp no_sensitive_value(value), do: no_sensitive_value(value, "input")

  defp no_sensitive_value(value, path) when is_map(value) do
    Enum.reduce_while(value, :ok, fn {key, nested}, :ok ->
      safe_key = if is_atom(key), do: Atom.to_string(key), else: "key"

      if sensitive?(safe_key),
        do: {:halt, error("PL-EVIDENCE-SENSITIVE", path, "remove sensitive evidence data")},
        else: {
          :cont,
          no_sensitive_value(nested, path)
        }
    end)
  end

  defp no_sensitive_value(value, path) when is_list(value),
    do: Enum.reduce_while(value, :ok, fn item, :ok -> {:cont, no_sensitive_value(item, path)} end)

  defp no_sensitive_value(value, path) when is_binary(value),
    do:
      if(sensitive?(value),
        do: error("PL-EVIDENCE-SENSITIVE", path, "remove sensitive evidence data"),
        else: :ok
      )

  defp no_sensitive_value(_, _), do: :ok

  defp sensitive?(value) do
    normalized = String.downcase(value)

    Enum.any?(@sensitive_terms, &String.contains?(normalized, &1)) or
      String.starts_with?(normalized, "http")
  end

  defp valid_versions(input) do
    with :ok <- decimal_version(input[:schema_version], "schema_version"),
         :ok <- semver(input[:crosswake_version]),
         :ok <- decimal_version(input[:template_version], "template_version"),
         :ok <- git_ref(input[:commit_ref]) do
      :ok
    end
  end

  defp decimal_version(value, path) when is_binary(value) and byte_size(value) in 1..8 do
    if String.match?(value, ~r/^[0-9]+$/),
      do: :ok,
      else: error("PL-EVIDENCE-VERSION", path, "use a bounded decimal version")
  end

  defp decimal_version(_, path),
    do: error("PL-EVIDENCE-VERSION", path, "use a bounded decimal version")

  defp semver(value) when is_binary(value) and byte_size(value) <= 32 do
    if String.match?(
         value,
         ~r/^(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/
       ),
       do: :ok,
       else: error("PL-EVIDENCE-VERSION", "crosswake_version", "use a bounded semantic version")
  end

  defp semver(_),
    do: error("PL-EVIDENCE-VERSION", "crosswake_version", "use a bounded semantic version")

  defp git_ref(value) when is_binary(value) do
    if String.match?(value, ~r/^git-(?:[0-9a-f]{40}|[0-9a-f]{64})$/),
      do: :ok,
      else: error("PL-EVIDENCE-COMMIT", "commit_ref", "use a full opaque Git reference")
  end

  defp git_ref(_),
    do: error("PL-EVIDENCE-COMMIT", "commit_ref", "use a full opaque Git reference")

  defp valid_route(value) do
    if is_binary(value) and String.match?(value, ~r/^route-[0-9a-f]{16}$/),
      do: :ok,
      else: error("PL-EVIDENCE-ROUTE", "route_id", "use an opaque route reference")
  end

  defp valid_assertions(values) do
    valid? =
      is_list(values) and values != [] and length(values) <= length(@assertion_ids) and
        Enum.uniq(values) == values and Enum.all?(values, &(&1 in @assertion_ids))

    if valid?,
      do: :ok,
      else: error("PL-EVIDENCE-ASSERTION", "assertion_ids", "use closed assertion references")
  end

  defp enum(value, allowed, path) do
    if value in allowed,
      do: :ok,
      else: error("PL-EVIDENCE-VALUE", path, "use a closed evidence value")
  end

  defp utc(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, _date_time, 0} -> :ok
      _ -> error("PL-EVIDENCE-TIME", "captured_at", "use a UTC ISO-8601 capture time")
    end
  end

  defp utc(_), do: error("PL-EVIDENCE-TIME", "captured_at", "use a UTC ISO-8601 capture time")

  defp source_hashes(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn
      %{kind: kind, canonical_bytes: bytes} = source, {:ok, hashes}
      when map_size(source) == 2 and kind in @approved_kinds and is_binary(bytes) ->
        case approved_hash(kind, bytes) do
          {:ok, digest} ->
            {:cont, {:ok, [%{kind: kind, digest: digest} | hashes]}}

          _ ->
            {:halt,
             error("PL-EVIDENCE-HASH", "approved_hashes", "use approved canonical sources")}
        end

      _, _ ->
        {:halt, error("PL-EVIDENCE-HASH", "approved_hashes", "use approved canonical sources")}
    end)
    |> then(fn
      {:ok, hashes} -> {:ok, Enum.reverse(hashes)}
      error -> error
    end)
  end

  defp source_hashes(_),
    do: error("PL-EVIDENCE-HASH", "approved_hashes", "use approved canonical sources")

  defp valid_hashes(values) when is_list(values),
    do:
      if(Enum.all?(values, &valid_hash?/1),
        do: :ok,
        else: error("PL-EVIDENCE-HASH", "approved_hashes", "use approved SHA-256 records")
      )

  defp valid_hashes(_),
    do: error("PL-EVIDENCE-HASH", "approved_hashes", "use approved SHA-256 records")

  defp valid_hash?(%{kind: kind, digest: digest})
       when kind in @approved_kinds and is_binary(digest),
       do: String.match?(digest, ~r/^[a-f0-9]{64}$/)

  defp valid_hash?(_), do: false

  defp hash_to_map(%{kind: kind, digest: digest}),
    do: %{"kind" => Atom.to_string(kind), "digest" => digest}

  defp enumerate(stage) do
    if File.dir?(stage),
      do: walk(stage, stage),
      else: error("PL-EVIDENCE-PATH", "artifact", "use a readable evidence directory")
  end

  defp walk(root, current) do
    with {:ok, names} <- File.ls(current) do
      Enum.reduce_while(names, {:ok, []}, fn name, {:ok, paths} ->
        path = Path.join(current, name)
        relative = Path.relative_to(path, root)

        case File.lstat(path) do
          {:ok, %{type: :directory}} ->
            case walk(root, path) do
              {:ok, nested} -> {:cont, {:ok, paths ++ nested}}
              error -> {:halt, error}
            end

          {:ok, %{type: :regular}} ->
            {:cont, {:ok, paths ++ [relative]}}

          _ ->
            {:halt, error("PL-EVIDENCE-TYPE", relative, "remove unsafe staged entries")}
        end
      end)
    else
      _ -> error("PL-EVIDENCE-READ", "artifact", "make staged evidence readable")
    end
  end

  defp ensure_only_evidence([@artifact_name]), do: :ok

  defp ensure_only_evidence(_),
    do: error("PL-EVIDENCE-ARTIFACT", "artifact", "retain only the approved evidence file")

  defp scan_file(path) do
    case File.read(path) do
      {:ok, bytes} -> scan_bytes(bytes, @artifact_name)
      _ -> error("PL-EVIDENCE-READ", @artifact_name, "make staged evidence readable")
    end
  end

  defp read_evidence(stage) do
    with {:ok, bytes} <- File.read(Path.join(stage, @artifact_name)),
         {:ok, decoded} <- Jason.decode(bytes),
         {:ok, evidence} <- string_map_to_evidence(decoded) do
      {:ok, evidence}
    else
      _ -> error("PL-EVIDENCE-SCAN", @artifact_name, "use canonical approved evidence")
    end
  end

  defp scan_bytes(bytes, path) do
    with {:ok, decoded} <- Jason.decode(bytes),
         :ok <- no_sensitive_value(decoded, path),
         {:ok, evidence} <- string_map_to_evidence(decoded),
         true <- Jason.encode!(to_map(evidence)) == bytes do
      :ok
    else
      _ -> error("PL-EVIDENCE-SCAN", path, "use canonical approved evidence")
    end
  end

  defp string_map_to_evidence(map) when is_map(map) do
    atomized =
      Enum.reduce_while(map, %{}, fn {key, value}, acc ->
        case Enum.find(@schema_keys, &(Atom.to_string(&1) == key)) do
          nil ->
            {:halt, :invalid}

          field ->
            case decode_value(field, value) do
              {:ok, decoded} -> {:cont, Map.put(acc, field, decoded)}
              :error -> {:halt, :invalid}
            end
        end
      end)

    case atomized do
      :invalid -> error("PL-EVIDENCE-SCAN", @artifact_name, "use declared evidence keys")
      attrs -> validate_fields(attrs)
    end
  end

  defp string_map_to_evidence(_),
    do: error("PL-EVIDENCE-SCAN", @artifact_name, "use canonical evidence JSON")

  defp decode_value(field, value) when field in [:status, :outcome],
    do: decode_enum(value, @outcomes)

  defp decode_value(:retention_label, value), do: decode_enum(value, @retention_labels)
  defp decode_value(:device_class, value), do: decode_enum(value, @device_classes)

  defp decode_value(:approved_hashes, values) when is_list(values),
    do: decode_hashes(values)

  defp decode_value(:approved_hashes, _), do: :error
  defp decode_value(_, value), do: {:ok, value}

  defp decode_hashes(values) do
    Enum.reduce_while(values, {:ok, []}, fn
      %{"kind" => kind, "digest" => digest}, {:ok, hashes} ->
        case decode_enum(kind, @approved_kinds) do
          {:ok, approved_kind} ->
            {:cont, {:ok, [%{kind: approved_kind, digest: digest} | hashes]}}

          :error ->
            {:halt, :error}
        end

      _, _ ->
        {:halt, :error}
    end)
    |> then(fn
      {:ok, hashes} -> {:ok, Enum.reverse(hashes)}
      :error -> :error
    end)
  end

  defp decode_enum(value, allowed) when is_binary(value) do
    case Enum.find(allowed, &(Atom.to_string(&1) == value)) do
      nil -> :error
      atom -> {:ok, atom}
    end
  end

  defp decode_enum(_, _), do: :error

  defp validate_fields(input) do
    with :ok <- exact_keys(input),
         :ok <- no_sensitive_value(input),
         :ok <- valid_versions(input),
         :ok <- valid_route(input[:route_id]),
         :ok <- valid_assertions(input[:assertion_ids]),
         :ok <- enum(input[:status], @outcomes, "status"),
         :ok <- enum(input[:outcome], @outcomes, "outcome"),
         :ok <- utc(input[:captured_at]),
         :ok <- enum(input[:retention_label], @retention_labels, "retention_label"),
         :ok <- enum(input[:device_class], @device_classes, "device_class"),
         :ok <- valid_hashes(input[:approved_hashes]) do
      {:ok, struct!(__MODULE__, input)}
    end
  end

  defp require_sources([]), do: :ok

  defp require_sources(_),
    do: error("PL-EVIDENCE-HASH-SOURCE", "approved_hashes", "supply approved canonical sources")

  defp verify_sources(hashes, sources) do
    with {:ok, source_hashes} <- source_hashes(sources), true <- source_hashes == hashes do
      :ok
    else
      _ ->
        error(
          "PL-EVIDENCE-HASH-SOURCE",
          "approved_hashes",
          "supply matching approved canonical sources"
        )
    end
  end

  defp safe_destination(path),
    do:
      if(Path.type(path) == :absolute and not String.contains?(path, ".."),
        do: :ok,
        else: error("PL-EVIDENCE-PATH", "artifact", "use an absolute safe destination")
      )

  defp write_evidence(stage, evidence),
    do: File.write(Path.join(stage, @artifact_name), Jason.encode!(to_map(evidence)), [:binary])

  defp run_hook(nil), do: :ok
  defp run_hook(fun) when is_function(fun, 0), do: fun.()

  defp run_hook(_),
    do: error("PL-EVIDENCE-PROMOTE", "artifact", "inspect the safe evidence inputs")

  defp error(rule_id, path, remediation),
    do: {:error, %Error{rule_id: rule_id, path: path, remediation: remediation}}
end
