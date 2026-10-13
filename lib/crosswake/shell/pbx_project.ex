defmodule Crosswake.Shell.PBXProject do
  @moduledoc false

  @punctuation [?{, ?}, ?(, ?), ?=, ?;, ?,]
  @whitespace [9, 10, 13, 32]

  def parse(contents) when is_binary(contents) do
    with {:ok, tokens} <- tokenize(String.to_charlist(contents), []),
         {:ok, value, []} <- parse_value(tokens),
         {:ok, normalized} <- normalize(value),
         true <- is_map(normalized) do
      {:ok, normalized}
    else
      _ -> {:error, :invalid_project}
    end
  rescue
    _ -> {:error, :invalid_project}
  end

  defp tokenize([], acc), do: {:ok, Enum.reverse(acc)}
  defp tokenize([char | rest], acc) when char in @whitespace, do: tokenize(rest, acc)
  defp tokenize([?/, ?* | rest], acc), do: skip_block_comment(rest, acc)
  defp tokenize([?/, ?/ | rest], acc), do: skip_line_comment(rest, acc)

  defp tokenize([?" | rest], acc) do
    with {:ok, value, tail} <- quoted(rest, []) do
      tokenize(tail, [{:scalar, value} | acc])
    end
  end

  defp tokenize([char | rest], acc) when char in @punctuation,
    do: tokenize(rest, [char | acc])

  defp tokenize(chars, acc) do
    case atom(chars, []) do
      {[], _} -> {:error, :invalid_project}
      {value, rest} -> tokenize(rest, [{:scalar, List.to_string(value)} | acc])
    end
  end

  defp skip_block_comment([?*, ?/ | rest], acc), do: tokenize(rest, acc)
  defp skip_block_comment([_ | rest], acc), do: skip_block_comment(rest, acc)
  defp skip_block_comment([], _acc), do: {:error, :invalid_project}

  defp skip_line_comment([?\n | rest], acc), do: tokenize(rest, acc)
  defp skip_line_comment([_ | rest], acc), do: skip_line_comment(rest, acc)
  defp skip_line_comment([], acc), do: tokenize([], acc)

  defp quoted([?\\, escaped | rest], acc) do
    value =
      case escaped do
        ?n -> ?\n
        ?r -> ?\r
        ?t -> ?\t
        other -> other
      end

    quoted(rest, [value | acc])
  end

  defp quoted([?" | rest], acc), do: {:ok, acc |> Enum.reverse() |> List.to_string(), rest}
  defp quoted([char | rest], acc), do: quoted(rest, [char | acc])
  defp quoted([], _acc), do: {:error, :invalid_project}

  defp atom([char | _] = chars, acc) when char in @whitespace or char in @punctuation,
    do: {Enum.reverse(acc), chars}

  defp atom([?/, next | _] = chars, acc) when next in [?*, ?/],
    do: {Enum.reverse(acc), chars}

  defp atom([char | rest], acc), do: atom(rest, [char | acc])
  defp atom([], acc), do: {Enum.reverse(acc), []}

  defp parse_value([?{ | rest]), do: parse_dictionary(rest, [])
  defp parse_value([?( | rest]), do: parse_array(rest, [])
  defp parse_value([{:scalar, value} | rest]), do: {:ok, {:scalar, value}, rest}
  defp parse_value(_), do: {:error, :invalid_project}

  defp parse_dictionary([?} | rest], pairs), do: {:ok, {:dictionary, Enum.reverse(pairs)}, rest}

  defp parse_dictionary([{:scalar, key}, ?= | rest], pairs) do
    with {:ok, value, [?; | tail]} <- parse_value(rest) do
      parse_dictionary(tail, [{key, value} | pairs])
    end
  end

  defp parse_dictionary(_, _), do: {:error, :invalid_project}

  defp parse_array([?) | rest], values), do: {:ok, {:array, Enum.reverse(values)}, rest}

  defp parse_array(tokens, values) do
    with {:ok, value, rest} <- parse_value(tokens) do
      case rest do
        [?, | tail] ->
          case tail do
            [?) | after_array] -> {:ok, {:array, Enum.reverse([value | values])}, after_array}
            _ -> parse_array(tail, [value | values])
          end

        [?) | after_array] ->
          {:ok, {:array, Enum.reverse([value | values])}, after_array}

        _ ->
          {:error, :invalid_project}
      end
    end
  end

  defp normalize({:scalar, value}), do: {:ok, value}

  defp normalize({:array, values}) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, acc} ->
      case normalize(value) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      error -> error
    end
  end

  defp normalize({:dictionary, pairs}) do
    if length(pairs) != MapSet.size(MapSet.new(Enum.map(pairs, &elem(&1, 0)))) do
      {:error, :duplicate_key}
    else
      Enum.reduce_while(pairs, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case normalize(value) do
          {:ok, normalized} -> {:cont, {:ok, Map.put(acc, key, normalized)}}
          error -> {:halt, error}
        end
      end)
    end
  end
end
