defmodule Crosswake.ProofLane.Evidence do
  @moduledoc """
  Builds the deliberately small, privacy-safe proof-lane evidence artifact.

  Evidence is an allowlist contract, not a generic diagnostic envelope.  The
  same final-byte scanner is used by hashing, read-only checking, and promotion.
  """

  alias Crosswake.ProofLane.PhysicalIphoneContract

  @legacy_schema_keys [
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
  @physical_schema_keys @legacy_schema_keys ++ [:ios_runtime_line]
  @schema_keys @physical_schema_keys
  @outcomes [:passed, :blocked, :unavailable]
  @retention_labels [:brief, :ephemeral]
  @device_classes [:ios, :simulator, :unknown, :physical_iphone]
  @artifact_name "proof-lane-evidence.json"
  @complete_name ".complete"
  @approved_kinds [:evidence_json, :navigation_shell_advisory, :physical_iphone_run_contract]
  @phase_160_assertion_ids ~w(scope_partition lifecycle_fence per_event_reauthorization atomic_idempotency safe_observation disablement)
  @physical_assertion_ids PhysicalIphoneContract.assertions() |> Enum.map(& &1.id)
  @assertion_ids ~w(browser_offline_island shell_boot auth_continuity relaunch_persistence replay_prerequisite pack_audio_prerequisite) ++
                   @phase_160_assertion_ids ++
                   ~w(PL-IOS-NAV-TOPOLOGY PL-IOS-NAV-PATCH-DEPTH PL-IOS-NAV-NAVIGATE-ONCE PL-IOS-NAV-RESTORE PL-IOS-NAV-TABS-BACK PL-IOS-NAV-MARKER-INSETS PL-IOS-NAV-FOCUS) ++
                   @physical_assertion_ids

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
    map = %{
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

    if evidence.device_class == :physical_iphone,
      do: Map.put(map, "ios_runtime_line", evidence.ios_runtime_line),
      else: map
  end

  @spec approved_hash(atom(), binary()) :: result(String.t())
  def approved_hash(kind, bytes) when kind in @approved_kinds and is_binary(bytes) do
    with :ok <- scan_source(kind, bytes) do
      {:ok, :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)}
    end
  end

  def approved_hash(_, _),
    do: error("PL-EVIDENCE-HASH-KIND", "artifact", "use an approved sanitized artifact")

  defp scan_source(:evidence_json, bytes), do: scan_bytes(bytes, @artifact_name)

  defp scan_source(:navigation_shell_advisory, bytes),
    do: Crosswake.ProofLane.NavigationShellAdvisory.scan(bytes)

  defp scan_source(:physical_iphone_run_contract, bytes), do: scan_physical_run_contract(bytes)

  @spec check(Path.t()) :: :ok | {:error, Error.t()}
  def check(path) when is_binary(path) do
    with {:ok, evidence} <- read_verified_evidence(path),
         :ok <- require_sources(evidence.approved_hashes) do
      :ok
    end
  end

  def check(_), do: error("PL-EVIDENCE-PATH", "artifact", "use a safe evidence directory")

  @spec check(Path.t(), list()) :: :ok | {:error, Error.t()}
  def check(path, sources) when is_binary(path) and is_list(sources) do
    with {:ok, evidence} <- read_verified_evidence(path),
         :ok <- verify_sources(evidence.approved_hashes, sources) do
      :ok
    end
  end

  def check(_, _),
    do: error("PL-EVIDENCE-HASH-SOURCE", "approved_hashes", "supply approved canonical sources")

  @spec scan_stage(Path.t()) :: :ok | {:error, Error.t()}
  def scan_stage(stage) when is_binary(stage) do
    with {:ok, _evidence} <- read_verified_evidence(stage) do
      :ok
    end
  end

  def scan_stage(_), do: error("PL-EVIDENCE-PATH", "artifact", "use a safe evidence directory")

  @spec promote(map() | t(), Path.t()) :: :ok | {:error, Error.t()}
  def promote(candidate, destination), do: promote(candidate, destination, [])

  @spec promote(map() | t(), Path.t(), keyword()) :: :ok | {:error, Error.t()}
  def promote(candidate, destination, opts) when is_binary(destination) and is_list(opts) do
    with {:ok, evidence} <- normalize(candidate),
         {:ok, sources} <- promotion_sources(candidate),
         :ok <- safe_destination(destination),
         :ok <- promotion_class(evidence, destination),
         bytes = Jason.encode!(to_map(evidence)),
         :ok <- scan_bytes(bytes, @artifact_name),
         :ok <- verify_sources(evidence.approved_hashes, sources),
         :ok <- run_hook(Keyword.get(opts, :before_promote)),
         :ok <- Crosswake.ProofLane.NativePromotion.publish(destination, bytes),
         :ok <- check(destination, sources) do
      :ok
    else
      {:error, %Error{} = error} -> {:error, error}
      _ -> error("PL-EVIDENCE-PROMOTE", "artifact", "inspect the safe evidence inputs")
    end
  end

  def promote(_, _, _), do: error("PL-EVIDENCE-PATH", "artifact", "use a safe evidence directory")

  defp normalize(%__MODULE__{} = evidence), do: {:ok, evidence}
  defp normalize(input), do: build(input)

  defp promotion_sources(%__MODULE__{approved_hashes: []}), do: {:ok, []}

  defp promotion_sources(%__MODULE__{}),
    do: error("PL-EVIDENCE-HASH-SOURCE", "approved_hashes", "supply approved canonical sources")

  defp promotion_sources(input) when is_map(input),
    do: {:ok, Map.get(input, :approved_hashes, [])}

  defp promotion_sources(_),
    do: error("PL-EVIDENCE-HASH-SOURCE", "approved_hashes", "supply approved canonical sources")

  defp atom_keys(map) do
    if Enum.all?(Map.keys(map), &is_atom/1),
      do: :ok,
      else: error("PL-EVIDENCE-KEY", "input", "use declared evidence keys")
  end

  defp exact_keys(map) do
    keys = Map.keys(map) |> MapSet.new()

    if keys in [MapSet.new(@legacy_schema_keys), MapSet.new(@physical_schema_keys)],
      do: :ok,
      else: error("PL-EVIDENCE-KEY", "input", "use only declared evidence keys")
  end

  defp no_sensitive_value(value), do: no_sensitive_value(value, "input")

  defp no_sensitive_value(value, path) when is_map(value) do
    Enum.reduce_while(value, :ok, fn {key, nested}, :ok ->
      safe_key =
        if is_atom(key), do: Atom.to_string(key), else: if(is_binary(key), do: key, else: "key")

      if safe_key in ["assertion_ids", "assertions", "canonical_bytes"] do
        # Assertion values are validated against the closed allowlist below. Some
        # safe IDs intentionally contain substrings that the collateral scanner
        # rejects elsewhere (for example, "log" in a topology assertion). Canonical
        # source bytes are instead scanned by their closed kind dispatcher below.
        {:cont, :ok}
      else
        if sensitive?(safe_key) do
          {:halt, error("PL-EVIDENCE-SENSITIVE", path, "remove sensitive evidence data")}
        else
          case no_sensitive_value(nested, path) do
            :ok -> {:cont, :ok}
            error -> {:halt, error}
          end
        end
      end
    end)
  end

  defp no_sensitive_value(value, path) when is_list(value) do
    Enum.reduce_while(value, :ok, fn item, :ok ->
      case no_sensitive_value(item, path) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

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

  defp valid_physical_fields(input) do
    physical_ids = PhysicalIphoneContract.assertions() |> Enum.map(& &1.id)

    case input[:device_class] do
      :physical_iphone ->
        with :ok <- runtime_line(input[:ios_runtime_line]),
             true <- input[:assertion_ids] == physical_ids,
             true <- input[:status] == :passed and input[:outcome] == :passed,
             true <- physical_hashes?(input[:approved_hashes]) do
          :ok
        else
          false ->
            error("PL-EVIDENCE-PHYSICAL", "artifact", "use a complete passed physical record")

          {:error, _} ->
            error("PL-EVIDENCE-RUNTIME", "ios_runtime_line", "use a bounded iOS runtime line")
        end

      _ ->
        if Map.has_key?(input, :ios_runtime_line),
          do:
            error(
              "PL-EVIDENCE-PHYSICAL",
              "ios_runtime_line",
              "reserve runtime lines for physical records"
            ),
          else: :ok
    end
  end

  defp runtime_line(value) do
    case PhysicalIphoneContract.ios_runtime_line(value) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :invalid}
    end
  end

  defp physical_hashes?([%{kind: :physical_iphone_run_contract, digest: digest}]),
    do: is_binary(digest) and String.match?(digest, ~r/^[a-f0-9]{64}$/)

  defp physical_hashes?(_), do: false

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

  defp ensure_only_evidence(entries) do
    if Enum.sort(entries) == Enum.sort([@artifact_name, @complete_name]),
      do: :ok,
      else: error("PL-EVIDENCE-INTEGRITY", "artifact", "retain only approved complete evidence")
  end

  defp read_artifact(stage) do
    case File.read(Path.join(stage, @artifact_name)) do
      {:ok, bytes} -> {:ok, bytes}
      _ -> error("PL-EVIDENCE-INTEGRITY", @artifact_name, "retain readable complete evidence")
    end
  end

  defp verify_complete_marker(stage, bytes) do
    marker = Path.join(stage, @complete_name)

    with {:ok, %{type: :regular}} <- File.lstat(marker),
         {:ok, digest} <- File.read(marker),
         true <- byte_size(digest) == 64 and String.match?(digest, ~r/\A[a-f0-9]{64}\z/),
         expected <- Base.encode16(:crypto.hash(:sha256, bytes), case: :lower),
         true <- :crypto.hash_equals(digest, expected) do
      :ok
    else
      _ -> error("PL-EVIDENCE-INTEGRITY", "artifact", "retain complete digest-bound evidence")
    end
  end

  defp read_verified_evidence(stage) do
    with {:ok, entries} <- enumerate(stage),
         :ok <- ensure_only_evidence(entries),
         {:ok, bytes} <- read_artifact(stage),
         :ok <- verify_complete_marker(stage, bytes),
         :ok <- run_after_digest_barrier(),
         {:ok, evidence} <- decode_evidence(bytes, @artifact_name) do
      {:ok, evidence}
    end
  end

  defp scan_bytes(bytes, path) do
    with {:ok, _evidence} <- decode_evidence(bytes, path) do
      :ok
    end
  end

  defp decode_evidence(bytes, path) do
    with {:ok, decoded} <- Jason.decode(bytes),
         :ok <- no_sensitive_value(decoded, path),
         {:ok, evidence} <- string_map_to_evidence(decoded),
         true <- Jason.encode!(to_map(evidence)) == bytes do
      {:ok, evidence}
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
         :ok <- valid_hashes(input[:approved_hashes]),
         :ok <- valid_physical_fields(input) do
      {:ok, struct!(__MODULE__, Map.put_new(input, :ios_runtime_line, nil))}
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

  defp scan_physical_run_contract(bytes) do
    with {:ok, decoded} <- Jason.decode(bytes),
         :ok <- no_sensitive_value(decoded, "run_contract"),
         {:ok, canonical} <- decode_physical_run_contract(decoded),
         true <- Jason.encode!(canonical) == bytes do
      :ok
    else
      _ -> error("PL-EVIDENCE-HASH", "approved_hashes", "use an approved physical run contract")
    end
  end

  defp decode_physical_run_contract(
         %{
           "schema_version" => schema_version,
           "device_class" => "physical_iphone",
           "ios_runtime_line" => runtime_line,
           "outcome" => "passed",
           "assertions" => assertions
         } = input
       )
       when map_size(input) == 5 and is_integer(schema_version) and is_list(assertions) do
    expected = PhysicalIphoneContract.assertions()

    report =
      Enum.map(assertions, fn
        %{"id" => id, "owner" => owner, "outcome" => outcome} = assertion
        when map_size(assertion) == 3 and is_binary(id) and is_binary(owner) and
               is_binary(outcome) ->
          with {:ok, owner} <- decode_enum(owner, [:device_local, :backend_authority]),
               {:ok, outcome} <- decode_enum(outcome, @outcomes) do
            %{id: id, owner: owner, outcome: outcome}
          else
            _ -> :invalid
          end

        _ ->
          :invalid
      end)

    if schema_version == PhysicalIphoneContract.schema_version() and
         :invalid not in report and
         runtime_line(runtime_line) == :ok and
         PhysicalIphoneContract.validate_report(report) == :ok and
         Enum.all?(report, &(&1.outcome == :passed)) do
      {:ok,
       %{
         "schema_version" => schema_version,
         "device_class" => "physical_iphone",
         "ios_runtime_line" => runtime_line,
         "outcome" => "passed",
         "assertions" =>
           Enum.zip(report, expected)
           |> Enum.map(fn {%{id: id, owner: owner, outcome: outcome}, _} ->
             %{"id" => id, "owner" => Atom.to_string(owner), "outcome" => Atom.to_string(outcome)}
           end)
       }}
    else
      :error
    end
  end

  defp decode_physical_run_contract(_), do: :error

  defp safe_destination(path),
    do:
      if(Path.type(path) == :absolute and not String.contains?(path, ".."),
        do: :ok,
        else: error("PL-EVIDENCE-PATH", "artifact", "use an absolute safe destination")
      )

  defp promotion_class(%__MODULE__{device_class: :physical_iphone}, _destination), do: :ok

  defp promotion_class(_evidence, destination) do
    if Path.basename(destination) == "physical_iphone",
      do: error("PL-EVIDENCE-PHYSICAL", "artifact", "promote only a complete physical record"),
      else: :ok
  end

  if Mix.env() == :test do
    @after_digest_barrier {__MODULE__, :after_digest_barrier}

    defp run_after_digest_barrier do
      case Process.get(@after_digest_barrier) do
        nil ->
          :ok

        fun when is_function(fun, 0) ->
          result =
            try do
              {:barrier_return, fun.()}
            rescue
              _ -> :barrier_failure
            catch
              _, _ -> :barrier_failure
            end

          case result do
            {:barrier_return, :ok} ->
              :ok

            _ ->
              error("PL-EVIDENCE-INTEGRITY", "artifact", "retain complete digest-bound evidence")
          end

        _ ->
          error("PL-EVIDENCE-INTEGRITY", "artifact", "retain complete digest-bound evidence")
      end
    end
  else
    defp run_after_digest_barrier, do: :ok
  end

  defp run_hook(nil), do: :ok

  defp run_hook(fun) when is_function(fun, 0) do
    result =
      try do
        {:hook_return, fun.()}
      rescue
        _ -> :hook_failure
      catch
        _, _ -> :hook_failure
      end

    case result do
      {:hook_return, :ok} -> :ok
      _ -> error("PL-EVIDENCE-PROMOTE", "artifact", "inspect the safe evidence inputs")
    end
  end

  defp run_hook(_),
    do: error("PL-EVIDENCE-PROMOTE", "artifact", "inspect the safe evidence inputs")

  defp error(rule_id, path, remediation),
    do: {:error, %Error{rule_id: rule_id, path: path, remediation: remediation}}
end
