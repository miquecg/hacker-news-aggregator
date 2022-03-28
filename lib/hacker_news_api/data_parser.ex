defmodule HackerNewsApi.DataParser do
  @moduledoc """
  Data parsing utilities.
  """

  @typedoc """
  Both strings are normalized to lowercase when parsing.
  """
  @type media_type :: {type_subtype :: String.t(), charset :: nil | String.t()}

  @type not_url :: :malformed_url | :missing_scheme | :missing_path | :missing_host
  @type not_media_type :: :not_media_type

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

  @spec parse_media_type(String.t()) :: ok(media_type) | error(not_media_type)
  def parse_media_type(media_type) when is_binary(media_type) do
    parts =
      media_type
      |> String.trim_leading()
      |> String.downcase()
      |> String.split(~r{\s*;\s*}, trim: true)

    case parse_media_type(parts, []) do
      :error -> {:error, :not_media_type}
      media_type -> {:ok, media_type}
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
