defmodule HackerNewsApi.Resource.TopStories do
  @moduledoc """
  Top stories.
  """

  alias HackerNewsApi.DataParser

  defstruct [:url]

  @opaque t :: %__MODULE__{
            url: String.t()
          }

  @type option :: {:scheme, String.t()} | {:path, String.t()}
  @type opts :: [option]

  @defaults [scheme: "https", path: "/v0/topstories"]

  @doc """
  Creates a `__MODULE__` struct.

  Defaults provided:
  - scheme: "https"
  - path: resource path

  They can be overridden passing a second
  argument of `t:opts/0`.
  """
  @spec new(String.t(), opts) :: t
  def new(host, opts \\ []) do
    opts = Keyword.merge(@defaults, opts)
    {:ok, url} = DataParser.parse_url(host, opts)
    struct(__MODULE__, url: to_string(url))
  end

  defimpl HackerNewsApi.Resource do
    def request(%{url: url}), do: {:get, url, []}
  end
end
