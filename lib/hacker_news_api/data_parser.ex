defmodule HackerNewsApi.DataParser do
  @moduledoc """
  Data parsing utilities.
  """

  @typep uri :: URI.t() | String.t()
  @typep ok(t) :: {:ok, t}
  @typep error(t) :: {:error, t}
  @typep not_url :: error(:malformed | :missing_scheme | :missing_path | :missing_host)

  @spec parse_url(uri, Access.t()) :: ok(URI.t()) | not_url
  def parse_url(uri, params)

  def parse_url(uri, params) when is_binary(uri) do
    case URI.new(uri) do
      {:ok, uri} -> parse_url(uri, params)
      {:error, _} -> {:error, :malformed}
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
end
