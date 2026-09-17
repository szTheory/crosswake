defmodule Crosswake.ReleaseCandidate.Identity do
  @moduledoc false

  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @digest_pattern ~r/\A[0-9a-f]{64}\z/
  @keys ~w(
    version ref head tree base coordinates config_digests workflow_digests
    package_digests proofs mirror run
  )a
  @proof_statuses ~w(PASS FAIL MISSING AMBIGUOUS)
  @run_statuses ~w(QUEUED IN_PROGRESS COMPLETED)
  @run_conclusions ~w(NONE SUCCESS FAILURE CANCELLED TIMED_OUT)

  @spec normalize!(map(), keyword()) :: map()
  def normalize!(identity, opts \\ []) do
    unless exact_map?(identity, @keys), do: invalid!()
    consistent? = Keyword.get(opts, :consistent?, true)
    version = version!(identity.version, consistent?)

    normalized = %{
      version: version,
      ref: sha!(identity.ref),
      head: sha!(identity.head),
      tree: sha!(identity.tree),
      base: sha!(identity.base),
      coordinates:
        normalize_list!(identity.coordinates, ~w(id coordinate)a, fn coordinate ->
          normalize_coordinate!(coordinate, version, consistent?)
        end),
      config_digests:
        normalize_list!(identity.config_digests, ~w(id sha256)a, &normalize_digest!/1),
      workflow_digests:
        normalize_list!(identity.workflow_digests, ~w(id sha256)a, &normalize_digest!/1),
      package_digests:
        normalize_list!(
          identity.package_digests,
          ~w(id outer_sha256 payload_sha256 metadata_sha256)a,
          &normalize_package!/1
        ),
      proofs: normalize_list!(identity.proofs, ~w(id status sha256)a, &normalize_proof!/1),
      mirror: normalize_mirror!(identity.mirror),
      run: normalize_run!(identity.run)
    }

    if consistent? do
      unless normalized.ref == normalized.head, do: invalid!()
      unless normalized.run.head == normalized.head, do: invalid!()
      unless normalized.mirror.tag == "v#{normalized.version}", do: invalid!()
    end

    normalized
  rescue
    KeyError -> invalid!()
  end

  @spec same?(map(), map()) :: boolean()
  def same?(left, right), do: left == right

  @spec ready?(map()) :: boolean()
  def ready?(identity) do
    Enum.all?(identity.proofs, &(&1.status == "PASS")) and
      identity.run.status == "COMPLETED" and identity.run.conclusion == "SUCCESS"
  end

  defp normalize_coordinate!(entry, version, consistent?) do
    id = id!(entry.id)
    coordinate = bounded_string!(entry.coordinate)

    unless Regex.match?(~r/\A[a-z0-9._-]+@[0-9]+\.[0-9]+\.[0-9]+\z/, coordinate),
      do: invalid!()

    if consistent? and not String.ends_with?(coordinate, "@" <> version), do: invalid!()
    %{id: id, coordinate: coordinate}
  end

  defp normalize_digest!(entry), do: %{id: id!(entry.id), sha256: digest!(entry.sha256)}

  defp normalize_package!(entry) do
    %{
      id: id!(entry.id),
      outer_sha256: digest!(entry.outer_sha256),
      payload_sha256: digest!(entry.payload_sha256),
      metadata_sha256: digest!(entry.metadata_sha256)
    }
  end

  defp normalize_proof!(entry) do
    status = enum!(entry.status, @proof_statuses)
    %{id: id!(entry.id), status: status, sha256: digest!(entry.sha256)}
  end

  defp normalize_mirror!(mirror) do
    unless exact_map?(mirror, ~w(split main tag plan_sha256)a), do: invalid!()

    %{
      split: sha!(mirror.split),
      main: sha!(mirror.main),
      tag: bounded_string!(mirror.tag),
      plan_sha256: digest!(mirror.plan_sha256)
    }
  end

  defp normalize_run!(run) do
    unless exact_map?(run, ~w(id head status conclusion)a), do: invalid!()
    unless is_integer(run.id) and run.id > 0, do: invalid!()

    %{
      id: run.id,
      head: sha!(run.head),
      status: enum!(run.status, @run_statuses),
      conclusion: enum!(run.conclusion, @run_conclusions)
    }
  end

  defp normalize_list!(entries, keys, mapper) when is_list(entries) and entries != [] do
    normalized =
      Enum.map(entries, fn entry ->
        unless exact_map?(entry, keys), do: invalid!()
        mapper.(entry)
      end)

    ids = Enum.map(normalized, & &1.id)
    unless Enum.uniq(ids) == ids, do: invalid!()
    Enum.sort_by(normalized, & &1.id)
  end

  defp normalize_list!(_entries, _keys, _mapper), do: invalid!()

  defp version!(version, _consistent?) when is_binary(version) do
    if Regex.match?(~r/\A[0-9]+\.[0-9]+\.[0-9]+\z/, version), do: version, else: invalid!()
  end

  defp version!(_version, _consistent?), do: invalid!()

  defp sha!(value) when is_binary(value) do
    if Regex.match?(@sha_pattern, value), do: value, else: invalid!()
  end

  defp sha!(_value), do: invalid!()

  defp digest!(value) when is_binary(value) do
    if Regex.match?(@digest_pattern, value), do: value, else: invalid!()
  end

  defp digest!(_value), do: invalid!()

  defp id!(value) when is_binary(value) do
    if byte_size(value) in 1..80 and Regex.match?(~r/\A[a-z0-9][a-z0-9._-]*\z/, value),
      do: value,
      else: invalid!()
  end

  defp id!(_value), do: invalid!()

  defp bounded_string!(value) when is_binary(value) and byte_size(value) in 1..160, do: value
  defp bounded_string!(_value), do: invalid!()

  defp enum!(value, allowed) do
    if value in allowed, do: value, else: invalid!()
  end

  defp exact_map?(value, keys) when is_map(value),
    do: Map.keys(value) |> Enum.sort() == Enum.sort(keys)

  defp exact_map?(_value, _keys), do: false

  defp invalid!, do: raise(ArgumentError, "candidate identity is invalid")
end
