defmodule Crosswake.Bridge.Commands.FilePicker do
  @moduledoc """
  Typed payload structs for the transfer-bound files.pick bridge command.
  """

  defmodule Request do
    @moduledoc false

    @enforce_keys [:transfer_id]
    defstruct [:transfer_id, media_types: [], multiple_allowed: false]

    @type t :: %__MODULE__{
            transfer_id: String.t(),
            media_types: [String.t()],
            multiple_allowed: boolean()
          }
  end

  defmodule Item do
    @moduledoc false

    @enforce_keys [:handle]
    defstruct [:handle, :name, :mime_type, :size_bytes, :native_type]

    @type t :: %__MODULE__{
            handle: String.t(),
            name: String.t() | nil,
            mime_type: String.t() | nil,
            size_bytes: non_neg_integer() | nil,
            native_type: String.t() | nil
          }
  end

  defmodule Success do
    @moduledoc false

    @enforce_keys [:transfer_id, :items]
    defstruct [:transfer_id, :items]

    @type t :: %__MODULE__{
            transfer_id: String.t(),
            items: [Item.t()]
          }
  end

  defmodule Canceled do
    @moduledoc false

    @enforce_keys [:transfer_id]
    defstruct [:transfer_id, detail: %{}]

    @type t :: %__MODULE__{
            transfer_id: String.t(),
            detail: map()
          }
  end

  @spec new_request(keyword()) :: {:ok, Request.t()}
  def new_request(attrs) when is_list(attrs) do
    {:ok,
     %Request{
       transfer_id: attrs |> Keyword.fetch!(:transfer_id) |> normalize_identifier("transfer_id"),
       media_types: attrs |> Keyword.get(:media_types, []) |> normalize_media_types(),
       multiple_allowed: attrs |> Keyword.get(:multiple_allowed, false) |> normalize_boolean("multiple_allowed")
     }}
  end

  @spec new_item(keyword()) :: Item.t()
  def new_item(attrs) when is_list(attrs) do
    %Item{
      handle: attrs |> Keyword.fetch!(:handle) |> normalize_identifier("handle"),
      name: attrs |> Keyword.get(:name) |> normalize_optional_string("name"),
      mime_type: attrs |> Keyword.get(:mime_type) |> normalize_optional_string("mime_type"),
      size_bytes: attrs |> Keyword.get(:size_bytes) |> normalize_optional_size_bytes(),
      native_type: attrs |> Keyword.get(:native_type) |> normalize_optional_string("native_type")
    }
  end

  @spec new_success(keyword()) :: Success.t()
  def new_success(attrs) when is_list(attrs) do
    items =
      attrs
      |> Keyword.fetch!(:items)
      |> Enum.map(fn
        %Item{} = item -> item
        item when is_list(item) -> new_item(item)
      end)

    %Success{
      transfer_id: attrs |> Keyword.fetch!(:transfer_id) |> normalize_identifier("transfer_id"),
      items: items
    }
  end

  @spec new_canceled(keyword()) :: Canceled.t()
  def new_canceled(attrs) when is_list(attrs) do
    %Canceled{
      transfer_id: attrs |> Keyword.fetch!(:transfer_id) |> normalize_identifier("transfer_id"),
      detail: Keyword.get(attrs, :detail, %{})
    }
  end

  defp normalize_identifier(value, _field) when is_atom(value), do: Atom.to_string(value)

  defp normalize_identifier(value, _field) when is_binary(value) and byte_size(value) > 0,
    do: value

  defp normalize_identifier(value, field) do
    raise ArgumentError, "#{field} must be a non-empty string or atom, got: #{inspect(value)}"
  end

  defp normalize_media_types(media_types) when is_list(media_types) do
    Enum.map(media_types, &normalize_identifier(&1, "media_types"))
  end

  defp normalize_media_types(value) do
    raise ArgumentError, "media_types must be a list, got: #{inspect(value)}"
  end

  defp normalize_boolean(value, _field) when is_boolean(value), do: value

  defp normalize_boolean(value, field) do
    raise ArgumentError, "#{field} must be a boolean, got: #{inspect(value)}"
  end

  defp normalize_optional_string(nil, _field), do: nil
  defp normalize_optional_string(value, field), do: normalize_identifier(value, field)

  defp normalize_optional_size_bytes(nil), do: nil
  defp normalize_optional_size_bytes(value) when is_integer(value) and value >= 0, do: value

  defp normalize_optional_size_bytes(value) do
    raise ArgumentError, "size_bytes must be a non-negative integer or nil, got: #{inspect(value)}"
  end
end
