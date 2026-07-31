defmodule Crosswake.Adoption.RouteInventory do
  @moduledoc """
  Closed, sanitized route-row validation for first-adopter planning inputs.

  This module deliberately records only opaque route references and low-cardinality
  posture. It is not a runtime route registry and never supplies route-local safety
  values from product-surface defaults.
  """

  defmodule ValidationError do
    @moduledoc false
    defexception [:message, :rule_id, :route_ref, :field]
  end

  @status_values [:confirmed_sanitized, :known_default, :unknown_blocking, :not_applicable]
  @fields [
    :route_id,
    :path_pattern,
    :runtime_owner,
    :offline_posture,
    :mutation_categories,
    :staleness_class,
    :auth,
    :recent_auth,
    :scope_posture,
    :media_requirement,
    :fallbacks,
    :disablement,
    :queued_data_retention
  ]
  @safety_fields @fields -- [:route_id, :path_pattern]
  @forbidden_fields [
    :raw_answer,
    :answer,
    :media,
    :transcript,
    :credential,
    :credentials,
    :account_id,
    :device_id,
    :token,
    :url,
    :endpoint,
    :digest,
    :exact_bytes,
    :flag_name
  ]

  @schema NimbleOptions.new!(
            route_id: [type: :any, required: true],
            path_pattern: [type: :any, required: true],
            runtime_owner: [type: :any, required: true],
            offline_posture: [type: :any, required: true],
            mutation_categories: [type: :any, required: true],
            staleness_class: [type: :any, required: true],
            auth: [type: :any, required: true],
            recent_auth: [type: :any, required: true],
            scope_posture: [type: :any, required: true],
            media_requirement: [type: :any, required: true],
            fallbacks: [type: :any, required: true],
            disablement: [type: :any, required: true],
            queued_data_retention: [type: :any, required: true]
          )

  @enforce_keys @fields
  defstruct @fields

  @type status :: :confirmed_sanitized | :known_default | :unknown_blocking | :not_applicable
  @type posture :: %{required(:status) => status(), optional(:value) => term()}
  @type t :: %__MODULE__{route_id: String.t(), path_pattern: String.t()}

  @spec status_values() :: [status()]
  def status_values, do: @status_values

  @spec validate(keyword() | map()) :: {:ok, t()} | {:error, ValidationError.t()}
  def validate(input) do
    with {:ok, options} <- normalize_input(input),
         :ok <- reject_forbidden_fields(options),
         :ok <- reject_unknown_fields(options),
         :ok <- require_fields(options),
         {:ok, validated} <- NimbleOptions.validate(options, @schema),
         {:ok, route_id} <- validate_route_id(validated[:route_id]),
         {:ok, path_pattern} <- validate_path_pattern(validated[:path_pattern], route_id),
         {:ok, postures} <- validate_postures(validated, route_id),
         :ok <- validate_route_invariants(postures, route_id) do
      {:ok, struct!(__MODULE__, [route_id: route_id, path_pattern: path_pattern] ++ postures)}
    end
  end

  @spec validate!(keyword() | map()) :: t()
  def validate!(input) do
    case validate(input) do
      {:ok, row} -> row
      {:error, error} -> raise error
    end
  end

  @spec validate_inventory([keyword() | map()]) :: {:ok, [t()]} | {:error, ValidationError.t()}
  def validate_inventory(rows) when is_list(rows) do
    with {:ok, validated} <- validate_rows(rows, []), :ok <- reject_collisions(validated) do
      {:ok, validated}
    end
  end

  def validate_inventory(_rows), do: {:error, error("RI-INVALID", "unresolved", "inventory")}

  @spec promotion_status(t() | [t()]) :: {:eligible, t() | [t()]} | {:blocked, map()}
  def promotion_status([]), do: {:blocked, %{reason: :empty_inventory, fields: []}}

  def promotion_status(%__MODULE__{} = row) do
    case unknown_fields(row) do
      [] -> {:eligible, row}
      fields -> {:blocked, %{reason: :unknown_blocking, route_ref: row.route_id, fields: fields}}
    end
  end

  def promotion_status(rows) when is_list(rows) do
    blocked =
      rows
      |> Enum.map(&promotion_status/1)
      |> Enum.filter(&match?({:blocked, _}, &1))

    case blocked do
      [] -> {:eligible, rows}
      [{:blocked, detail} | _] -> {:blocked, detail}
    end
  end

  defp normalize_input(input) when is_list(input) do
    if Keyword.keyword?(input),
      do: {:ok, input},
      else: {:error, error("RI-INVALID", "unresolved", "route_row")}
  end

  defp normalize_input(input) when is_map(input), do: {:ok, Map.to_list(input)}
  defp normalize_input(_input), do: {:error, error("RI-INVALID", "unresolved", "route_row")}

  defp reject_forbidden_fields(options) do
    case Enum.find(Keyword.keys(options), &(&1 in @forbidden_fields)) do
      nil -> :ok
      field -> {:error, error("RI-FORBIDDEN_FIELD", route_ref(options), field)}
    end
  end

  defp reject_unknown_fields(options) do
    case Enum.find(Keyword.keys(options), &(&1 not in @fields and &1 not in @forbidden_fields)) do
      nil -> :ok
      field -> {:error, error("RI-UNKNOWN_FIELD", route_ref(options), field)}
    end
  end

  defp require_fields(options) do
    case Enum.find(@fields, &(not Keyword.has_key?(options, &1))) do
      nil -> :ok
      field -> {:error, error("RI-REQUIRED", route_ref(options), field)}
    end
  end

  defp validate_route_id(value) when is_binary(value) do
    if Regex.match?(~r/^[a-z][a-z0-9-]*$/, value) do
      {:ok, value}
    else
      {:error, error("RI-INVALID", "unresolved", "route_id")}
    end
  end

  defp validate_route_id(_value), do: {:error, error("RI-INVALID", "unresolved", "route_id")}

  defp validate_path_pattern(value, route_ref) when is_binary(value) do
    if Regex.match?(~r|^/[a-z0-9_/:.-]*$|, value) and value != "/" do
      {:ok, value}
    else
      {:error, error("RI-INVALID", route_ref, "path_pattern")}
    end
  end

  defp validate_path_pattern(_value, route_ref),
    do: {:error, error("RI-INVALID", route_ref, "path_pattern")}

  defp validate_postures(validated, route_ref) do
    Enum.reduce_while(@safety_fields, {:ok, []}, fn field, {:ok, acc} ->
      case validate_posture(field, validated[field], route_ref) do
        {:ok, posture} -> {:cont, {:ok, [{field, posture} | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> then(fn
      {:ok, postures} -> {:ok, Enum.reverse(postures)}
      error -> error
    end)
  end

  defp validate_posture(field, %{status: status} = posture, route_ref)
       when status in @status_values do
    case status do
      :unknown_blocking ->
        {:ok, %{status: status}}

      :not_applicable ->
        {:ok, %{status: status}}

      :known_default ->
        {:error, error("RI-SAFETY_STATUS", route_ref, field)}

      :confirmed_sanitized ->
        with {:ok, value} <- fetch_value(posture, route_ref, field),
             :ok <- validate_value(field, value, route_ref) do
          {:ok, %{status: status, value: value}}
        end
    end
  end

  defp validate_posture(field, _posture, route_ref),
    do: {:error, error("RI-INVALID", route_ref, field)}

  defp fetch_value(%{value: value}, _route_ref, _field) when not is_nil(value), do: {:ok, value}

  defp fetch_value(_posture, route_ref, field),
    do: {:error, error("RI-INVALID", route_ref, field)}

  defp validate_value(:runtime_owner, value, _route_ref)
       when value in [:live_view, :offline_island, :native_screen], do: :ok

  defp validate_value(:offline_posture, value, _route_ref)
       when value in [:unavailable, :cached_read_only, :local_first], do: :ok

  defp validate_value(:mutation_categories, value, route_ref)
       when is_list(value) and value != [] do
    if Enum.all?(value, &(&1 in [:none, :answer_submission, :progress_update])) do
      :ok
    else
      {:error, error("RI-INVALID", route_ref, "mutation_categories")}
    end
  end

  defp validate_value(:staleness_class, value, _route_ref)
       when value in [:not_cacheable, :fresh_only, :bounded], do: :ok

  defp validate_value(:auth, value, _route_ref)
       when value in [:unauthenticated, :authenticated, :recent_auth], do: :ok

  defp validate_value(:recent_auth, value, _route_ref) when value in [:not_required, :required],
    do: :ok

  defp validate_value(:scope_posture, value, _route_ref),
    do:
      validate_closed_map(value, %{
        scope: [:opaque_partitioned],
        logout: [:stops_replay],
        account_switch: [:stops_replay]
      })

  defp validate_value(:media_requirement, value, _route_ref),
    do:
      validate_closed_map(value, %{
        requirement: [:required, :not_required],
        size_band: [:tiny, :small, :medium, :large],
        codec_family: [:aac, :mp3, :opus],
        integrity: [:verified, :not_applicable]
      })

  defp validate_value(:fallbacks, value, _route_ref),
    do:
      validate_closed_map(value, %{
        online: [:serve],
        offline: [:queue_local, :read_only, :block],
        denied: [:block],
        corrupt_pack: [:block],
        disabled: [:retain_and_block]
      })

  defp validate_value(:disablement, value, _route_ref),
    do: validate_closed_map(value, %{entry: [:server_enforced], replay: [:server_reauthorized]})

  defp validate_value(:queued_data_retention, value, _route_ref)
       when value in [:retain_until_resolution, :not_applicable], do: :ok

  defp validate_value(field, _value, route_ref),
    do: {:error, error("RI-INVALID", route_ref, field)}

  defp validate_closed_map(value, required) when is_map(value) do
    if Map.keys(value) |> Enum.sort() == Map.keys(required) |> Enum.sort() and
         Enum.all?(required, fn {key, allowed} -> Map.get(value, key) in allowed end) do
      :ok
    else
      {:error, error("RI-INVALID", "unresolved", "posture")}
    end
  end

  defp validate_closed_map(_value, _required),
    do: {:error, error("RI-INVALID", "unresolved", "posture")}

  defp validate_route_invariants(postures, route_ref) do
    with :ok <- validate_local_mutation_invariants(postures, route_ref),
         :ok <- validate_recent_auth_invariants(postures, route_ref) do
      :ok
    end
  end

  defp validate_local_mutation_invariants(postures, route_ref) do
    if posture_value(postures, :offline_posture) == :local_first do
      with :ok <- require_posture_value(postures, :runtime_owner, :offline_island, route_ref),
           :ok <- require_actionable_mutation(postures, route_ref),
           :ok <- reject_not_applicable(postures, :scope_posture, route_ref),
           :ok <- reject_not_applicable(postures, :fallbacks, route_ref),
           :ok <- reject_not_applicable(postures, :disablement, route_ref),
           :ok <- reject_not_applicable(postures, :queued_data_retention, route_ref) do
        :ok
      end
    else
      :ok
    end
  end

  defp validate_recent_auth_invariants(postures, route_ref) do
    cond do
      posture_value(postures, :auth) == :recent_auth and
          posture_value(postures, :recent_auth) != :required ->
        {:error, error("RI-ROUTE_INVARIANT", route_ref, "recent_auth")}

      posture_value(postures, :recent_auth) == :required and
          posture_value(postures, :auth) != :recent_auth ->
        {:error, error("RI-ROUTE_INVARIANT", route_ref, "auth")}

      true ->
        :ok
    end
  end

  defp require_posture_value(postures, field, expected, route_ref) do
    if posture_value(postures, field) == expected,
      do: :ok,
      else: {:error, error("RI-ROUTE_INVARIANT", route_ref, Atom.to_string(field))}
  end

  defp require_actionable_mutation(postures, route_ref) do
    case posture_value(postures, :mutation_categories) do
      categories when is_list(categories) ->
        if Enum.any?(categories, &(&1 != :none)),
          do: :ok,
          else: {:error, error("RI-ROUTE_INVARIANT", route_ref, "mutation_categories")}

      _other ->
        {:error, error("RI-ROUTE_INVARIANT", route_ref, "mutation_categories")}
    end
  end

  defp reject_not_applicable(postures, field, route_ref) do
    if posture_status(postures, field) == :not_applicable,
      do: {:error, error("RI-ROUTE_INVARIANT", route_ref, Atom.to_string(field))},
      else: :ok
  end

  defp posture_value(postures, field) do
    case Keyword.fetch!(postures, field) do
      %{status: :confirmed_sanitized, value: value} -> value
      _posture -> nil
    end
  end

  defp posture_status(postures, field), do: postures |> Keyword.fetch!(field) |> Map.fetch!(:status)

  defp validate_rows([], acc), do: {:ok, Enum.reverse(acc)}

  defp validate_rows([row | rest], acc) do
    case validate(row) do
      {:ok, validated} -> validate_rows(rest, [validated | acc])
      {:error, error} -> {:error, error}
    end
  end

  defp reject_collisions(rows) do
    case Enum.find(rows, fn row -> Enum.count(rows, &(&1.route_id == row.route_id)) > 1 end) do
      nil -> reject_path_collisions(rows)
      row -> {:error, error("RI-DUPLICATE_ROUTE_ID", row.route_id, "route_id")}
    end
  end

  defp reject_path_collisions(rows) do
    case Enum.find(rows, fn row ->
           Enum.count(rows, &(&1.path_pattern == row.path_pattern)) > 1
         end) do
      nil -> :ok
      row -> {:error, error("RI-DUPLICATE_PATH_PATTERN", row.route_id, "path_pattern")}
    end
  end

  defp unknown_fields(row) do
    Enum.filter(@safety_fields, fn field -> Map.fetch!(row, field).status == :unknown_blocking end)
  end

  defp route_ref(options) do
    case Keyword.get(options, :route_id) do
      value when is_binary(value) ->
        if Regex.match?(~r/^[a-z][a-z0-9-]*$/, value), do: value, else: "unresolved"

      _other ->
        "unresolved"
    end
  end

  defp error(rule_id, route_ref, field) do
    %ValidationError{
      rule_id: rule_id,
      route_ref: route_ref,
      field: field,
      message:
        "#{rule_id}: route #{route_ref}, field #{field}; remediation: provide a closed sanitized route value"
    }
  end
end
