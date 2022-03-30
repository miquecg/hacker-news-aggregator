defprotocol HackerNewsApi.Resource do
  @moduledoc """
  Protocol that HTTP resources of the Hacker News API must implement.
  """

  # Only GET requests at this moment.
  @type method :: :get
  @type url :: String.t()
  @type header :: {name :: String.t(), value :: String.t()}
  @type headers :: [header]

  @type request :: {method, url, headers}

  @doc """
  Must return a tuple representing a `t:request/0`.
  """
  @spec request(t) :: request
  def request(resource)
end

defmodule HackerNewsApi.BaseResource do
  @moduledoc """
  Allows to define an implementation of `HackerNewsApi.Resource`
  with `Kernel.use/2`.
  """

  @host Application.compile_env!(:hacker_news, [:api, :host])

  @doc false
  defmacro __using__(opts) do
    path = Keyword.fetch!(opts, :path)
    url = to_string(new!(@host, opts))

    quote do
      defstruct [:url]

      @opaque t :: %__MODULE__{
                url: String.t()
              }

      @spec new :: t
      def new do
        struct(__MODULE__, url: unquote(url))
      end

      @path unquote(path)

      @spec path :: String.t()
      def path, do: @path

      defimpl HackerNewsApi.Resource do
        def request(%{url: url}), do: {:get, url, []}
      end
    end
  end

  alias HackerNewsApi.{DataParser, Error}

  @typep host :: String.t()
  @type option :: {:scheme, String.t()} | {:path, String.t()}
  @type opts :: [option]

  @typep ok :: {:ok, URI.t()}
  @typep error :: {:error, Error.Params.t()}

  @defaults [scheme: "https"]

  @doc """
  Creates a `URI` struct.

  Defaults provided:
  - scheme: "https"
  """
  @spec new(host, opts) :: ok | error
  def new(host, opts \\ []) do
    opts = Keyword.merge(@defaults, opts)

    case DataParser.parse_url(host, opts) do
      {:ok, _url} = ok ->
        ok

      {:error, error} ->
        {:error, build_error(error, host: host, opts: opts)}
    end
  end

  @spec new!(host, opts) :: URI.t() | no_return()
  def new!(host, opts \\ []) do
    case new(host, opts) do
      {:ok, url} -> url
      {:error, error} -> raise error
    end
  end

  defp build_error(error, params) do
    %Error.Params{
      module: __MODULE__,
      params: params,
      error: error
    }
  end
end
