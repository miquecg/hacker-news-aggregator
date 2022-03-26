defmodule HackerNewsApi.Resource.TopStories do
  @moduledoc """
  Top stories.

  Implements `HackerNewsApi.Resource` protocol.
  """

  alias HackerNewsApi.{DataParser, Error}

  defstruct [:url]

  @opaque t :: %__MODULE__{
            url: String.t()
          }

  @type option :: {:scheme, String.t()} | {:path, String.t()}
  @type opts :: [option]

  @typep host :: String.t()
  @typep ok :: {:ok, t}
  @typep error :: {:error, Error.Params.t()}

  @defaults [scheme: "https", path: "/v0/topstories.json"]

  @spec new!(host, opts) :: t | no_return()
  def new!(host, opts \\ []) do
    case new(host, opts) do
      {:ok, url} -> url
      {:error, error} -> raise error
    end
  end

  @doc """
  Creates a `__MODULE__` struct.

  Defaults provided:
  - scheme: "https"
  - path: resource path

  They can be overridden passing a second
  argument of `t:opts/0`.
  """
  @spec new(host, opts) :: ok | error
  def new(host, opts \\ []) do
    opts = Keyword.merge(@defaults, opts)

    case DataParser.parse_url(host, opts) do
      {:ok, url} ->
        {:ok, build(url)}

      {:error, error} ->
        error = build_error(error, host: host, opts: opts)
        {:error, error}
    end
  end

  defp build(url), do: struct(__MODULE__, url: to_string(url))

  defp build_error(error, params) do
    %Error.Params{
      module: __MODULE__,
      params: params,
      error: error
    }
  end

  defimpl HackerNewsApi.Resource do
    def request(%{url: url}), do: {:get, url, []}
  end
end
