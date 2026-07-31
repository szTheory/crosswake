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
  def check(path) when is_binary(path), do: scan_stage(path)
  def check(_), do: error("PL-EVIDENCE-PATH", "artifact", "use a safe evidence directory")

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
  def promote(candidate, destination) when is_binary(destination) do
    with {:ok, evidence} <- normalize(candidate),
         :ok <- safe_destination(destination),
         :ok <- absent(destination) do
      stage = destination <> ".stage-" <> Integer.to_string(System.unique_integer([:positive]))

      try do
        with :ok <- File.mkdir(stage),
             :ok <- write_evidence(stage, evidence),
             :ok <- scan_stage(stage),
             :ok <- promote_stage(stage, destination) do
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

  def promote(_, _), do: error("PL-EVIDENCE-PATH", "artifact", "use a safe evidence directory")

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
    fields = [:schema_version, :crosswake_version, :template_version, :commit_ref]

    if Enum.all?(
         fields,
         &(is_binary(input[&1]) and String.match?(input[&1], ~r/^[A-Za-z0-9._-]{1,64}$/))
       ),
       do: :ok,
       else: error("PL-EVIDENCE-VERSION", "version", "use bounded version and commit references")
  end

  defp valid_route(value) do
    if is_binary(value) and String.match?(value, ~r/^route-[0-9a-f]{16}$/),
      do: :ok,
      else: error("PL-EVIDENCE-ROUTE", "route_id", "use an opaque route reference")
  end

  defp valid_assertions(values) do
    valid? =
      is_list(values) and values != [] and length(values) <= 32 and
        Enum.all?(values, &(is_binary(&1) and String.match?(&1, ~r/^[a-z][a-z0-9_]{0,63}$/)))

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
          nil -> {:halt, :invalid}
          field -> {:cont, Map.put(acc, field, decode_value(field, value))}
        end
      end)

    case atomized do
      :invalid -> error("PL-EVIDENCE-SCAN", @artifact_name, "use declared evidence keys")
      attrs -> build(attrs)
    end
  end

  defp string_map_to_evidence(_),
    do: error("PL-EVIDENCE-SCAN", @artifact_name, "use canonical evidence JSON")

  defp decode_value(field, value)
       when field in [:status, :outcome, :retention_label, :device_class] and is_binary(value),
       do: String.to_existing_atom(value)

  defp decode_value(:approved_hashes, values) when is_list(values),
    do:
      Enum.map(values, fn
        %{"kind" => kind, "digest" => digest} ->
          %{kind: String.to_existing_atom(kind), digest: digest}

        _ ->
          %{}
      end)

  defp decode_value(_, value), do: value

  defp safe_destination(path),
    do:
      if(Path.type(path) == :absolute and not String.contains?(path, ".."),
        do: :ok,
        else: error("PL-EVIDENCE-PATH", "artifact", "use an absolute safe destination")
      )

  defp absent(path),
    do:
      if(File.exists?(path),
        do: error("PL-EVIDENCE-COLLISION", "artifact", "choose an unused evidence destination"),
        else: :ok
      )

  defp write_evidence(stage, evidence),
    do: File.write(Path.join(stage, @artifact_name), Jason.encode!(to_map(evidence)), [:binary])

  defp promote_stage(stage, destination) do
    case File.rename(stage, destination) do
      :ok ->
        :ok

      {:error, _} ->
        error("PL-EVIDENCE-COLLISION", "artifact", "choose an unused evidence destination")
    end
  end

  defp error(rule_id, path, remediation),
    do: {:error, %Error{rule_id: rule_id, path: path, remediation: remediation}}
end
