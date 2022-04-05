defmodule HackerNewsApi.Client do
  @moduledoc """
  Behaviour that HTTP clients must adhere to.
  """

  alias HackerNewsApi.{Client.Response, Resource}
  alias HackerNewsApi.Error.{MediaTypeError, ResourceError}

  @typedoc """
  Lowercase type/subtype (e.g. application/json).
  UTF-8 charset assumed.
  """
  @type media_type :: String.t()
  @type decoder :: (body :: binary() -> {:ok, term()} | {:error, Exception.t()})

  @type max_retries :: 0..5
  @type min_delay_ms :: 100..1_000
  @type max_delay_ms :: 500..5_000

  @type option ::
          {:decode, {media_type, decoder}}
          | {:retries, {max_retries, min_delay_ms, max_delay_ms}}
  @type opts :: [option]

  @typep exception :: Exception.t()

  @typep resource :: Resource.t()
  @typep method :: Resource.method()
  @typep url :: Resource.url()
  @typep headers :: Resource.headers()

  @typep response :: Response.t()

  @typep ok(t) :: {:ok, t}
  @typep error(t) :: {:error, t}

  @callback do_request(method, url, headers) :: ok(response) | error(exception)

  @adapter Application.compile_env!(:hacker_news, :adapter)
  @defaults [{:retries, {4, 100, 500}}]

  @spec request(resource, opts) :: ok(response) | error(exception)
  def request(resource, opts \\ []) do
    opts = Keyword.merge(@defaults, opts)
    request(@adapter, resource, opts)
  end

  @typep retries :: non_neg_integer()

  @spec request(module(), resource, opts, retries) :: ok(response) | error(exception)
  def request(adapter, resource, opts, retries \\ 0) do
    {method, url, headers} = Resource.request(resource)

    case adapter.do_request(method, url, headers) do
      {:ok, %{status: 429}} -> retry(adapter, resource, opts, retries)
      {:ok, response} -> process_response(response, opts)
      {:error, _} = error -> error
    end
  end

  @spec retry(module(), resource, opts, retries) :: ok(response) | error(exception)
  defp retry(adapter, resource, opts, retries) do
    {max_retries, min_delay, max_delay} = Keyword.fetch!(opts, :retries)

    if retries < max_retries do
      :ok = backoff(retries, min_delay, max_delay)
      request(adapter, resource, opts, retries + 1)
    else
      error_too_many_requests(resource)
    end
  end

  @spec backoff(retries, min_delay_ms, max_delay_ms) :: :ok
  defp backoff(retries, min_delay, max_delay) do
    factor = Integer.pow(2, retries)
    random_delay = Enum.random(min_delay..max_delay)
    time = factor * random_delay

    Process.send_after(self(), :retry, time)

    receive do
      :retry -> :ok
    end
  end

  defp error_too_many_requests(resource) do
    {:error, %ResourceError{resource: resource, reason: :too_many_requests}}
  end

  @spec process_response(response, opts) :: ok(response) | error(exception)
  defp process_response(response, opts) do
    case Enum.reduce_while(opts, response, &process_with_option/2) do
      %{} = response -> {:ok, response}
      {:error, _} = error -> error
    end
  end

  defp process_with_option({:decode, {media_type, decoder}}, response) do
    with :ok <- match_content_type(response, media_type),
         {:ok, decoded} <- decoder.(response.raw_body) do
      {:cont, %{response | body: decoded}}
    else
      {:error, _} = error -> {:halt, error}
    end
  end

  defp process_with_option(_option, response), do: {:cont, response}

  defp match_content_type(response, media_type) do
    case Response.get_media_type(response) do
      {:ok, {^media_type, "utf-8"}} -> :ok
      {:ok, {_, _} = value} -> error_media_type(unsupported: value)
      {:error, error} -> error_media_type(error)
    end
  end

  defp error_media_type(info), do: {:error, MediaTypeError.exception(info)}
end
