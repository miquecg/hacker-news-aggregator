defmodule HackerNewsApi.DataParser do
  @moduledoc """
  Data parsing utilities.
  """

  @typedoc """
  Both strings are normalized to lowercase when parsing.
  """
  @type media_type :: {type_subtype :: String.t(), charset :: nil | String.t()}
  @type path_params :: [String.t()]

  @type not_media_type :: :not_media_type
  @type not_path_param :: {param :: String.t(), offending_char :: <<_::8>>}
  @type not_url :: :malformed_url | :missing_scheme | :missing_path | :missing_host

  @typep ok(t) :: {:ok, t}
  @typep error(t) :: {:error, t}

  @spec parse_url(URI.t() | String.t(), Access.t()) :: ok(URI.t()) | error(not_url)
  def parse_url(uri, params)

  def parse_url(uri, params) when is_binary(uri) do
    case URI.new(uri) do
      {:ok, uri} -> parse_url(uri, params)
      {:error, _} -> {:error, :malformed_url}
    end
  end

  def parse_url(%URI{scheme: nil} = uri, params) do
    case params[:scheme] do
      nil -> {:error, :missing_scheme}
      scheme -> parse_url("#{scheme}://#{to_string(uri)}", params)
    end
  end

  def parse_url(%URI{path: "/"} = uri, params) do
    parse_url(%{uri | path: nil}, params)
  end

  def parse_url(%URI{path: nil} = uri, params) do
    case params[:path] do
      nil ->
        {:error, :missing_path}

      path ->
        uri = URI.merge(uri, path)
        parse_url(uri, params)
    end
  end

  def parse_url(%URI{host: nil}, _), do: {:error, :missing_host}
  def parse_url(%URI{host: ""}, _), do: {:error, :missing_host}

  def parse_url(%URI{} = uri, _), do: {:ok, uri}

  @spec parse_path_params(String.t()) :: ok(path_params) | error(not_path_param)
  def parse_path_params(path) when is_binary(path) do
    segments = String.split(path, "/", trim: true)

    case parse_path_params(segments, []) do
      params when is_list(params) -> {:ok, Enum.reverse(params)}
      {:error, _} = error -> error
    end
  end

  defp parse_path_params(segments, acc) do
    pattern = :binary.compile_pattern([":"])

    Enum.reduce_while(segments, acc, fn segment, acc ->
      case match_param(segment, pattern) do
        param when is_binary(param) -> {:cont, [param | acc]}
        {:error, :no_match} -> {:cont, acc}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp match_param(segment, pattern) do
    case :binary.matches(segment, pattern) do
      [{prefix_size, _}] ->
        suffix_size = byte_size(segment) - prefix_size - 1
        <<_::binary-size(prefix_size), ?:, suffix::binary-size(suffix_size)>> = segment
        parse_suffix(suffix)

      [] ->
        {:error, :no_match}
    end
  end

  defp parse_suffix(<<h, t::binary>>)
       when h in ?a..?z or h in ?A..?Z,
       do: parse_suffix(t, <<?:, h>>)

  defp parse_suffix(<<h, _::binary>> = suffix), do: {:error, {suffix, <<h>>}}

  defp parse_suffix(<<h, t::binary>>, acc)
       when h in ?a..?z or h in ?A..?Z or h in ?0..?9 or h == ?_,
       do: parse_suffix(t, <<acc::binary, h>>)

  defp parse_suffix(_rest, acc), do: acc

  @spec parse_media_type(String.t()) :: ok(media_type) | error(not_media_type)
  def parse_media_type(media_type) when is_binary(media_type) do
    parts =
      media_type
      |> String.trim_leading()
      |> String.downcase()
      |> String.split(~r{\s*;\s*}, trim: true)

    case parse_media_type(parts, []) do
      media_type when is_tuple(media_type) -> {:ok, media_type}
      :error -> {:error, :not_media_type}
    end
  end

  defp parse_media_type([type_subtype | params], []) do
    with [_, _] <- split_in_two(type_subtype, "/") do
      parse_media_type(params, [type_subtype])
    end
  end

  defp parse_media_type([param | rest], media_type) do
    case split_in_two(param, "=") do
      ["charset", charset] ->
        parse_media_type([], [charset | media_type])

      _ ->
        parse_media_type(rest, media_type)
    end
  end

  defp parse_media_type([], [type_subtype]), do: {type_subtype, nil}

  defp parse_media_type([], media_type) do
    media_type
    |> Enum.reverse()
    |> List.to_tuple()
  end

  defp split_in_two(text, delimiter) do
    with [_] <- String.split(text, " "),
         [_, _] = parts <- String.split(text, delimiter) do
      parts
    else
      _ -> :error
    end
  end
end
