defmodule Crosswake.Shell.PBXProject do
  @moduledoc false
  @punctuation [?{, ?}, ?(, ?), ?=, ?;, ?,]
  @whitespace [9, 10, 13, 32]

  def parse(contents) do
    with {:ok, document} <- parse_document(contents), do: {:ok, document.value}
  end

  # Keep byte ranges from the same parse that establishes the semantic graph.
  # Migration can then edit owned values without reserializing host-owned bytes.
  def parse_document(contents) when is_binary(contents) do
    with {:ok, tokens} <- tokenize(contents, 0, []),
         {:ok, %{kind: :dictionary} = document, []} <- parse_value(tokens) do
      {:ok, document}
    else
      _ -> {:error, :invalid_project}
    end
  rescue
    _ -> {:error, :invalid_project}
  end

  defp tokenize(<<>>, _offset, acc), do: {:ok, Enum.reverse(acc)}

  defp tokenize(<<char, rest::binary>>, offset, acc) when char in @whitespace,
    do: tokenize(rest, offset + 1, acc)

  defp tokenize(<<"/*", rest::binary>>, offset, acc) do
    case :binary.match(rest, "*/") do
      {size, 2} ->
        tokenize(binary_part(rest, size + 2, byte_size(rest) - size - 2), offset + size + 4, acc)

      :nomatch ->
        {:error, :invalid_project}
    end
  end

  defp tokenize(<<"//", rest::binary>>, offset, acc) do
    case :binary.match(rest, "\n") do
      {size, 1} ->
        tokenize(binary_part(rest, size + 1, byte_size(rest) - size - 1), offset + size + 3, acc)

      :nomatch ->
        {:ok, Enum.reverse(acc)}
    end
  end

  defp tokenize(<<char, rest::binary>>, offset, acc) when char in @punctuation,
    do: tokenize(rest, offset + 1, [{char, offset, offset + 1} | acc])

  defp tokenize(<<"\"", rest::binary>> = input, offset, acc) do
    with {:ok, value, tail} <- quoted(rest, []) do
      finish = offset + byte_size(input) - byte_size(tail)
      tokenize(tail, finish, [{value, offset, finish} | acc])
    end
  end

  defp tokenize(input, offset, acc) do
    case atom(input, []) do
      {[], _} ->
        {:error, :invalid_project}

      {value, rest} ->
        finish = offset + byte_size(input) - byte_size(rest)

        tokenize(rest, finish, [
          {value |> Enum.reverse() |> IO.iodata_to_binary(), offset, finish} | acc
        ])
    end
  end

  defp quoted(<<"\\", char, rest::binary>>, acc) when char in [?n, ?r, ?t, ?\\, ?"] do
    value =
      case char do
        ?n -> "\n"
        ?r -> "\r"
        ?t -> "\t"
        other -> <<other>>
      end

    quoted(rest, [value | acc])
  end

  defp quoted(<<"\\", _::binary>>, _acc), do: {:error, :invalid_project}

  defp quoted(<<"\"", rest::binary>>, acc),
    do: {:ok, acc |> Enum.reverse() |> IO.iodata_to_binary(), rest}

  defp quoted(<<char::utf8, rest::binary>>, acc), do: quoted(rest, [<<char::utf8>> | acc])
  defp quoted(<<>>, _acc), do: {:error, :invalid_project}

  defp atom(<<char, _::binary>> = rest, acc)
       when char in @whitespace or char in @punctuation or char == ?",
       do: {acc, rest}

  defp atom(<<"/", next, _::binary>> = rest, acc) when next in [?*, ?/], do: {acc, rest}
  defp atom(<<char::utf8, rest::binary>>, acc), do: atom(rest, [<<char::utf8>> | acc])
  defp atom(<<>>, acc), do: {acc, <<>>}

  defp parse_value([{?{, start, _} | rest]), do: dictionary(rest, %{}, %{}, start)
  defp parse_value([{?(, start, _} | rest]), do: array(rest, [], [], start)

  defp parse_value([{value, start, finish} | rest]) when is_binary(value),
    do: {:ok, %{kind: :scalar, value: value, range: {start, finish}}, rest}

  defp parse_value(_), do: {:error, :invalid_project}

  defp dictionary([{?}, _, finish} | rest], value, children, start),
    do:
      {:ok, %{kind: :dictionary, value: value, children: children, range: {start, finish}}, rest}

  defp dictionary([{key, key_start, _}, {?=, _, _} | rest], value, children, start)
       when is_binary(key) do
    with false <- Map.has_key?(value, key),
         {:ok, child, [{?;, _, pair_end} | tail]} <- parse_value(rest) do
      dictionary(
        tail,
        Map.put(value, key, child.value),
        Map.put(children, key, Map.put(child, :pair, {key_start, pair_end})),
        start
      )
    else
      _ -> {:error, :invalid_project}
    end
  end

  defp dictionary(_, _, _, _), do: {:error, :invalid_project}

  defp array([{?), _, finish} | rest], values, children, start),
    do:
      {:ok,
       %{
         kind: :array,
         value: Enum.reverse(values),
         children: Enum.reverse(children),
         range: {start, finish}
       }, rest}

  defp array(tokens, values, children, start) do
    with {:ok, child, rest} <- parse_value(tokens) do
      case rest do
        [{?,, _, _} | tail] -> array(tail, [child.value | values], [child | children], start)
        [{?), _, _} | _] -> array(rest, [child.value | values], [child | children], start)
        _ -> {:error, :invalid_project}
      end
    end
  end
end
