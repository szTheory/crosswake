defmodule Crosswake.Policy.Schema do
  @moduledoc """
  NimbleOptions schema for Phase 1 Crosswake route policy declarations.
  """

  alias Crosswake.Transfer.Contracts
  alias Crosswake.Companions.Sigra.Contracts, as: SigraContracts
  alias Crosswake.Offline.ContentPack

  @runtime_values [:live_view, :offline_island, :native_screen]
  @offline_values [:unavailable, :cached_read_only, :local_first]
  @entry_values [:internal_only, :external]
  @security_values [:standard, :sensitive]
  @auth_posture_values [:strict_recent, :remembered_ok, :cached_read_only_ok]
  @auth_return_kind_values [:oauth, :passkey, :native_auth]
  @auth_return_transport_values [
    :http_callback,
    :verified_https_link,
    :custom_scheme,
    :bridge_event
  ]
  @auth_return_validation_values [
    :state,
    :nonce,
    :pkce,
    :redirect_uri,
    :link_verification,
    :expiry,
    :replay,
    :challenge,
    :origin,
    :rp_id,
    :user_verification,
    :callback_binding
  ]
  @provider_specific_auth_return_terms [
    :google,
    :github,
    :apple,
    :microsoft,
    :okta,
    :auth0,
    :google_oauth,
    :apple_passkey
  ]
  @pack_kind_values [:content, :media]
  @commerce_role_values [:paywall_entry, :purchase_intent, :restore_intent, :account_management]
  @provider_specific_commerce_terms [:storekit, :play_billing, :revenuecat]

  @schema NimbleOptions.new!(
            id: [
              type: {:custom, __MODULE__, :validate_identifier, []},
              required: true,
              type_spec: quote(do: String.t())
            ],
            runtime: [
              type: {:custom, __MODULE__, :validate_runtime, []},
              required: true,
              type_spec: quote(do: :live_view | :offline_island | :native_screen)
            ],
            offline: [
              type: {:in, @offline_values},
              default: :unavailable,
              type_spec: quote(do: :unavailable | :cached_read_only | :local_first)
            ],
            entry: [
              type: {:in, @entry_values},
              default: :internal_only,
              type_spec: quote(do: :internal_only | :external)
            ],
            cache_contract: [
              type: {:custom, __MODULE__, :validate_identifier, []},
              type_spec: quote(do: String.t() | nil)
            ],
            island_contract: [
              type: {:custom, __MODULE__, :validate_identifier, []},
              type_spec: quote(do: String.t() | nil)
            ],
            capabilities: [
              type: {:list, {:custom, __MODULE__, :validate_identifier, []}},
              default: [],
              type_spec: quote(do: [String.t()])
            ],
            commerce: [
              type: {:custom, __MODULE__, :validate_commerce_declaration, []},
              type_spec: quote(do: commerce_declaration() | nil)
            ],
            packs: [
              type: {:custom, __MODULE__, :validate_pack_requirements, []},
              default: [],
              type_spec: quote(do: [pack_requirement()])
            ],
            sync: [
              type: {:list, {:custom, __MODULE__, :validate_identifier, []}},
              default: [],
              type_spec: quote(do: [String.t()])
            ],
            transfers: [
              type: {:custom, __MODULE__, :validate_transfer_declarations, []},
              default: [],
              type_spec: quote(do: [Crosswake.Transfer.Contracts.declaration()])
            ],
            security: [
              type: {:in, @security_values},
              type_spec: quote(do: :standard | :sensitive)
            ],
            gated_by: [
              type: {:custom, __MODULE__, :validate_flag_key, []},
              type_spec: quote(do: atom() | nil)
            ],
            on_unavailable: [
              type: {:custom, __MODULE__, :validate_on_unavailable, []},
              type_spec: quote(do: :deny | {:fallback_phoenix, atom()} | nil)
            ],
            auth_min_level: [
              type: {:custom, __MODULE__, :validate_auth_min_level, []},
              type_spec: quote(do: atom() | nil)
            ],
            requires_recent_auth: [
              type: {:custom, __MODULE__, :validate_requires_recent_auth, []},
              type_spec: quote(do: pos_integer() | nil)
            ],
            auth_posture: [
              type: {:in, @auth_posture_values},
              type_spec: quote(do: auth_posture() | nil)
            ],
            auth_return: [
              type: {:custom, __MODULE__, :validate_auth_return_declaration, []},
              type_spec: quote(do: auth_return_declaration() | nil)
            ],
            notification_open: [
              type: {:custom, __MODULE__, :validate_notification_open, []},
              type_spec: quote(do: notification_open_declaration() | nil)
            ]
          )

  @type runtime :: :live_view | :offline_island | :native_screen
  @type offline :: :unavailable | :cached_read_only | :local_first
  @type entry :: :internal_only | :external
  @type security :: :standard | :sensitive
  @type auth_posture :: :strict_recent | :remembered_ok | :cached_read_only_ok
  @type auth_return_kind :: :oauth | :passkey | :native_auth
  @type notification_open_declaration :: true | %{actions: [atom()]}
  @type auth_return_transport ::
          :http_callback | :verified_https_link | :custom_scheme | :bridge_event
  @type auth_return_validation ::
          :state
          | :nonce
          | :pkce
          | :redirect_uri
          | :link_verification
          | :expiry
          | :replay
          | :challenge
          | :origin
          | :rp_id
          | :user_verification
          | :callback_binding
  @type auth_return_declaration :: %{
          kind: auth_return_kind() | nil,
          transport: auth_return_transport() | nil,
          return_route_id: String.t() | nil,
          validates: [auth_return_validation()]
        }
  @type pack_kind :: :content | :media
  @type commerce_role ::
          :paywall_entry | :purchase_intent | :restore_intent | :account_management
  @type commerce_declaration :: %{
          corridor: String.t() | nil,
          role: commerce_role() | nil
        }
  @type pack_integrity :: %{algorithm: String.t(), digest: String.t()}
  @type pack_requirement :: ContentPack.t()
  @type validated_options :: [
          id: String.t(),
          runtime: runtime(),
          offline: offline(),
          entry: entry(),
          cache_contract: String.t() | nil,
          island_contract: String.t() | nil,
          capabilities: [String.t()],
          commerce: commerce_declaration() | nil,
          packs: [pack_requirement()],
          sync: [String.t()],
          transfers: [Contracts.declaration()],
          security: security(),
          gated_by: atom() | nil,
          on_unavailable: :deny | {:fallback_phoenix, atom()} | nil,
          auth_min_level: atom() | nil,
          requires_recent_auth: pos_integer() | nil,
          auth_posture: auth_posture() | nil,
          auth_return: auth_return_declaration() | nil,
          notification_open: notification_open_declaration() | nil
        ]

  @spec schema() :: NimbleOptions.t()
  def schema, do: @schema

  @spec commerce_role_values() :: [commerce_role()]
  def commerce_role_values, do: @commerce_role_values

  @spec auth_posture_values() :: [auth_posture()]
  def auth_posture_values, do: @auth_posture_values

  @spec auth_return_kind_values() :: [auth_return_kind()]
  def auth_return_kind_values, do: @auth_return_kind_values

  @spec auth_return_transport_values() :: [auth_return_transport()]
  def auth_return_transport_values, do: @auth_return_transport_values

  @spec validate(keyword()) ::
          {:ok, validated_options()} | {:error, NimbleOptions.ValidationError.t()}
  def validate(options) when is_list(options) do
    NimbleOptions.validate(options, @schema)
  end

  @spec validate!(keyword()) :: validated_options()
  def validate!(options) when is_list(options) do
    NimbleOptions.validate!(options, @schema)
  end

  @spec validate_identifier(term()) :: {:ok, String.t()} | {:error, String.t()}
  def validate_identifier(value) when is_binary(value) and byte_size(value) > 0, do: {:ok, value}
  def validate_identifier(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def validate_identifier(_value), do: {:error, "expected a non-empty string or atom"}

  @spec validate_flag_key(term()) :: {:ok, atom()} | {:error, String.t()}
  def validate_flag_key(value) when is_atom(value) and value not in [true, false, nil] do
    str = Atom.to_string(value)

    if Regex.match?(~r/^[a-z_][a-z0-9_]*[?!]?$/, str) do
      {:ok, value}
    else
      {:error, "expected a plain atom identifier (e.g. :my_flag), got: #{inspect(value)}"}
    end
  end

  def validate_flag_key(value) do
    {:error, "expected a plain atom identifier (e.g. :my_flag), got: #{inspect(value)}"}
  end

  @spec validate_on_unavailable(term()) ::
          {:ok, :deny | {:fallback_phoenix, atom()} | nil} | {:error, String.t()}
  def validate_on_unavailable(nil), do: {:ok, nil}
  def validate_on_unavailable(:deny), do: {:ok, :deny}

  def validate_on_unavailable({:fallback_phoenix, route_id}) do
    case validate_flag_key(route_id) do
      {:ok, valid_id} ->
        {:ok, {:fallback_phoenix, valid_id}}

      {:error, _} ->
        {:error,
         "on_unavailable fallback_phoenix route_id must be a plain atom identifier (e.g. :home), got: #{inspect(route_id)}"}
    end
  end

  def validate_on_unavailable(value) do
    {:error,
     "expected on_unavailable to be :deny or {:fallback_phoenix, route_id}, got: #{inspect(value)}"}
  end

  @spec validate_auth_min_level(term()) :: {:ok, atom() | nil} | {:error, String.t()}
  def validate_auth_min_level(nil), do: {:ok, nil}

  def validate_auth_min_level(value) when is_atom(value) do
    if value in SigraContracts.mfa_level_vocabulary() do
      {:ok, value}
    else
      {:error,
       "expected auth_min_level in sigra MFA vocabulary, got invalid_mfa_level: #{inspect(value)}"}
    end
  end

  def validate_auth_min_level(value) do
    {:error,
     "expected auth_min_level in sigra MFA vocabulary, got invalid_mfa_level: #{inspect(value)}"}
  end

  @spec validate_requires_recent_auth(term()) :: {:ok, pos_integer() | nil} | {:error, String.t()}
  def validate_requires_recent_auth(nil), do: {:ok, nil}

  def validate_requires_recent_auth(value) when is_integer(value) and value > 0 do
    {:ok, value}
  end

  def validate_requires_recent_auth(value) do
    {:error, "expected requires_recent_auth as positive integer seconds, got: #{inspect(value)}"}
  end

  @spec validate_runtime(term()) :: {:ok, runtime()} | {:error, String.t()}
  def validate_runtime(:adapter),
    do: {:error, "runtime :adapter is a reserved future extension point"}

  def validate_runtime(value) when value in @runtime_values, do: {:ok, value}

  def validate_runtime(value) do
    {:error, "expected one of #{inspect(@runtime_values)}, got: #{inspect(value)}"}
  end

  @spec validate_commerce_declaration(term()) ::
          {:ok, commerce_declaration() | nil} | {:error, String.t()}
  def validate_commerce_declaration(nil), do: {:ok, nil}

  def validate_commerce_declaration(declaration) when is_list(declaration) do
    declaration
    |> Enum.into(%{})
    |> validate_commerce_declaration()
  end

  def validate_commerce_declaration(declaration) when is_map(declaration) do
    with {:ok, corridor} <-
           validate_optional_identifier(
             Map.get(declaration, :corridor, Map.get(declaration, "corridor"))
           ),
         {:ok, role} <-
           validate_commerce_role(Map.get(declaration, :role, Map.get(declaration, "role"))) do
      {:ok, %{corridor: corridor, role: role}}
    end
  end

  def validate_commerce_declaration(_value),
    do: {:error, "expected commerce declaration as a map or keyword list"}

  @spec validate_pack_requirements(term()) :: {:ok, [pack_requirement()]} | {:error, String.t()}
  def validate_pack_requirements(requirements) when is_list(requirements) do
    requirements
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {requirement, index}, {:ok, acc} ->
      case validate_pack_requirement(requirement) do
        {:ok, normalized} ->
          {:cont, {:ok, acc ++ [normalized]}}

        {:error, reason} ->
          {:halt, {:error, "invalid pack declaration at position #{index}: #{reason}"}}
      end
    end)
  end

  def validate_pack_requirements(_value), do: {:error, "expected a list of pack declarations"}

  @spec validate_transfer_declarations(term()) ::
          {:ok, [Contracts.declaration()]} | {:error, String.t()}
  def validate_transfer_declarations(declarations) when is_list(declarations) do
    declarations
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {declaration, index}, {:ok, acc} ->
      case Contracts.normalize_declaration(declaration) do
        {:ok, normalized} ->
          {:cont, {:ok, acc ++ [normalized]}}

        {:error, reason} ->
          {:halt, {:error, "invalid transfer declaration at position #{index}: #{reason}"}}
      end
    end)
  end

  def validate_transfer_declarations(_value),
    do: {:error, "expected a list of transfer declarations"}

  @spec validate_auth_return_declaration(term()) ::
          {:ok, auth_return_declaration() | nil} | {:error, String.t()}
  def validate_auth_return_declaration(nil), do: {:ok, nil}

  def validate_auth_return_declaration(declaration) when is_list(declaration) do
    declaration
    |> Enum.into(%{})
    |> validate_auth_return_declaration()
  end

  def validate_auth_return_declaration(declaration) when is_map(declaration) do
    with {:ok, kind} <-
           validate_auth_return_kind(Map.get(declaration, :kind, Map.get(declaration, "kind"))),
         {:ok, transport} <-
           validate_auth_return_transport(
             Map.get(declaration, :transport, Map.get(declaration, "transport"))
           ),
         {:ok, return_route_id} <-
           validate_optional_identifier(
             Map.get(declaration, :return_route_id, Map.get(declaration, "return_route_id"))
           ),
         {:ok, validates} <-
           validate_auth_return_validates(
             Map.get(declaration, :validates, Map.get(declaration, "validates", []))
           ) do
      {:ok,
       %{
         kind: kind,
         transport: transport,
         return_route_id: return_route_id,
         validates: validates
       }}
    end
  end

  def validate_auth_return_declaration(_value),
    do: {:error, "expected auth_return declaration as a map or keyword list"}

  defp validate_pack_requirement(%ContentPack{} = requirement), do: {:ok, requirement}

  defp validate_pack_requirement(requirement) when is_list(requirement) do
    requirement
    |> Enum.into(%{})
    |> validate_pack_requirement()
  end

  defp validate_pack_requirement(requirement) when is_map(requirement) do
    with {:ok, id} <- validate_identifier(Map.get(requirement, :id, Map.get(requirement, "id"))),
         {:ok, version} <-
           validate_pack_version(Map.get(requirement, :version, Map.get(requirement, "version"))),
         {:ok, kind} <-
           validate_pack_kind(Map.get(requirement, :kind, Map.get(requirement, "kind"))),
         {:ok, integrity} <-
           validate_pack_integrity(
             Map.get(requirement, :integrity, Map.get(requirement, "integrity"))
           ) do
      {:ok, %ContentPack{id: id, version: version, kind: kind, integrity: integrity}}
    end
  end

  defp validate_pack_requirement(_value), do: {:error, "expected a keyword list or map"}

  defp validate_pack_version(value) when is_binary(value) and byte_size(value) > 0,
    do: {:ok, value}

  defp validate_pack_version(_value),
    do: {:error, "pack version is required and must be a non-empty string"}

  defp validate_pack_kind(value) when value in @pack_kind_values, do: {:ok, value}

  defp validate_pack_kind(value) do
    {:error,
     "expected pack kind to be one of #{inspect(@pack_kind_values)}, got: #{inspect(value)}"}
  end

  defp validate_pack_integrity(nil), do: {:ok, nil}

  defp validate_pack_integrity(integrity) when is_list(integrity) do
    integrity
    |> Enum.into(%{})
    |> validate_pack_integrity()
  end

  defp validate_pack_integrity(integrity) when is_map(integrity) do
    with {:ok, algorithm} <-
           validate_identifier(Map.get(integrity, :algorithm, Map.get(integrity, "algorithm"))),
         {:ok, digest} <-
           validate_identifier(Map.get(integrity, :digest, Map.get(integrity, "digest"))) do
      {:ok, %{algorithm: algorithm, digest: digest}}
    end
  end

  defp validate_pack_integrity(_value),
    do: {:error, "pack integrity must be a map or keyword list with algorithm and digest"}

  defp validate_commerce_role(nil), do: {:ok, nil}
  defp validate_commerce_role(value) when value in @commerce_role_values, do: {:ok, value}

  defp validate_commerce_role(value) when value in @provider_specific_commerce_terms do
    {:error, "provider-specific commerce role #{inspect(value)} is not supported in route policy"}
  end

  defp validate_commerce_role(value) when is_binary(value) do
    cond do
      value in Enum.map(@commerce_role_values, &Atom.to_string/1) ->
        {:ok, String.to_existing_atom(value)}

      value in Enum.map(@provider_specific_commerce_terms, &Atom.to_string/1) ->
        {:error,
         "provider-specific commerce role #{inspect(value)} is not supported in route policy"}

      true ->
        {:error,
         "unsupported commerce role #{inspect(value)}; expected one of #{inspect(@commerce_role_values)}"}
    end
  end

  defp validate_commerce_role(value) do
    {:error,
     "unsupported commerce role #{inspect(value)}; expected one of #{inspect(@commerce_role_values)}"}
  end

  @spec validate_notification_open(term()) ::
          {:ok, true | %{actions: [atom()]} | nil} | {:error, String.t()}
  def validate_notification_open(nil), do: {:ok, nil}
  def validate_notification_open(false), do: {:ok, nil}
  def validate_notification_open(true), do: {:ok, true}

  def validate_notification_open(declaration) when is_list(declaration) do
    declaration
    |> Enum.into(%{})
    |> validate_notification_open()
  end

  def validate_notification_open(declaration) when is_map(declaration) do
    actions = Map.get(declaration, :actions, Map.get(declaration, "actions", []))

    if is_list(actions) and Enum.all?(actions, &is_atom/1) do
      {:ok, %{actions: actions}}
    else
      {:error, "expected notification_open actions to be a list of atoms"}
    end
  end

  def validate_notification_open(_value),
    do: {:error, "expected notification_open declaration to be a boolean, a keyword list, or a map"}

  defp validate_auth_return_kind(nil), do: {:ok, nil}

  defp validate_auth_return_kind(value) when value in @auth_return_kind_values, do: {:ok, value}

  defp validate_auth_return_kind(value) when value in @provider_specific_auth_return_terms do
    {:error,
     "provider-specific auth_return kind #{inspect(value)} is not supported in route policy"}
  end

  defp validate_auth_return_kind(value) when is_binary(value) do
    normalized = String.to_existing_atom(value)
    validate_auth_return_kind(normalized)
  rescue
    ArgumentError ->
      {:error,
       "unsupported auth_return kind #{inspect(value)}; expected one of #{inspect(@auth_return_kind_values)}"}
  end

  defp validate_auth_return_kind(value) do
    {:error,
     "unsupported auth_return kind #{inspect(value)}; expected one of #{inspect(@auth_return_kind_values)}"}
  end

  defp validate_auth_return_transport(nil), do: {:ok, nil}

  defp validate_auth_return_transport(value) when value in @auth_return_transport_values,
    do: {:ok, value}

  defp validate_auth_return_transport(value) when is_binary(value) do
    normalized = String.to_existing_atom(value)
    validate_auth_return_transport(normalized)
  rescue
    ArgumentError ->
      {:error,
       "unsupported auth_return transport #{inspect(value)}; expected one of #{inspect(@auth_return_transport_values)}"}
  end

  defp validate_auth_return_transport(value) do
    {:error,
     "unsupported auth_return transport #{inspect(value)}; expected one of #{inspect(@auth_return_transport_values)}"}
  end

  defp validate_auth_return_validates(values) when is_list(values) do
    values
    |> Enum.reduce_while({:ok, []}, fn value, {:ok, acc} ->
      case validate_auth_return_validation(value) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_auth_return_validates(_values),
    do: {:error, "auth_return validates must be a list"}

  defp validate_auth_return_validation(value) when value in @auth_return_validation_values,
    do: {:ok, value}

  defp validate_auth_return_validation(value) when is_binary(value) do
    normalized = String.to_existing_atom(value)
    validate_auth_return_validation(normalized)
  rescue
    ArgumentError ->
      {:error,
       "unsupported auth_return validation #{inspect(value)}; expected one of #{inspect(@auth_return_validation_values)}"}
  end

  defp validate_auth_return_validation(value) do
    {:error,
     "unsupported auth_return validation #{inspect(value)}; expected one of #{inspect(@auth_return_validation_values)}"}
  end

  defp validate_optional_identifier(nil), do: {:ok, nil}
  defp validate_optional_identifier(value), do: validate_identifier(value)
end
