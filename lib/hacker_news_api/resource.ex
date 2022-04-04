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

  alias HackerNewsApi.{DataParser, Error}

  require Error.Params

  @host Application.compile_env!(:hacker_news, [:api, :host])

  @doc false
  defmacro __using__(opts) do
    path = Keyword.fetch!(opts, :path)
    url = to_string(build_url!(@host, opts))

    [
      quote do
        defstruct [:url]

        @opaque t :: %__MODULE__{
                  url: String.t()
                }

        @path unquote(path)

        @spec path :: String.t()
        def path, do: @path

        defimpl HackerNewsApi.Resource do
          def request(%{url: url}), do: {:get, url, []}
        end
      end,
      quote_new(path, url)
    ]
  end

  defp quote_new(path, url) when is_binary(path) do
    {:ok, path_params} = DataParser.parse_path_params(path)
    quote_new(path_params, url)
  end

  defp quote_new([], url) do
    quote do
      @spec new :: {:ok, t}
      def new do
        {:ok, struct(__MODULE__, url: unquote(url))}
      end
    end
  end

  # sobelow_skip ["DOS.StringToAtom"]
  defp quote_new(path_params, url) do
    quote do
      alias HackerNewsApi.Error

      require Error.Params

      import HackerNewsApi.BaseResource, only: [replace_path_params: 3]

      @spec new(keyword()) :: {:ok, t} | {:error, Error.Params.t()}
      def new(args) do
        if contains?(args, unquote(path_params)) do
          url = replace_path_params(unquote(url), unquote(path_params), args)
          {:ok, struct(__MODULE__, url: url)}
        else
          {:error, Error.Params.build(:missing_path_params, args)}
        end
      end

      # sobelow_skip ["DOS.StringToAtom"]
      defp contains?(args, path_params) do
        Enum.all?(path_params, fn <<?:, param::binary>> ->
          Keyword.has_key?(args, String.to_atom(param))
        end)
      end
    end
  end

  @type option :: {:scheme, String.t()} | {:path, String.t()}
  @type opts :: [option]

  @typep ok(t) :: {:ok, t}
  @typep error(t) :: {:error, t}

  @doc """
  Creates a `URI` struct.

  Accepts a list of `t:option/0`.

  Options do not override existing URI parts.

  Defaults provided:
  - scheme: "https"
  """
  @spec build_url(String.t(), opts) :: ok(URI.t()) | error(Error.Params.t())
  def build_url(uri, opts \\ []) do
    case DataParser.parse_url(uri, opts) do
      {:ok, _url} = ok ->
        ok

      {:error, error} ->
        {:error, Error.Params.build(error, uri: uri, opts: opts)}
    end
  end

  @spec build_url!(String.t(), opts) :: URI.t() | no_return()
  def build_url!(uri, opts \\ []) do
    case build_url(uri, opts) do
      {:ok, url} -> url
      {:error, error} -> raise error
    end
  end

  @typep path_params :: DataParser.path_params()

  # sobelow_skip ["DOS.StringToAtom"]
  @spec replace_path_params(String.t(), path_params, keyword()) :: String.t()
  def replace_path_params(url, path_params, values) do
    String.replace(url, path_params, fn <<":", param::binary>> ->
      key = String.to_atom(param)
      to_string(values[key])
    end)
  end
end
