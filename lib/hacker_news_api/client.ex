defmodule HackerNewsApi.Client do
  @moduledoc """
  Behaviour that HTTP clients must adhere to.
  """

  alias HackerNewsApi.{Client.Response, Error, Resource}

  @adapter Application.compile_env!(:hacker_news, :adapter)

  @type return :: return(Response.t())
  @type return(t) :: {:ok, t} | {:error, Exception.t()}

  @typedoc """
  Lowercase type/subtype (e.g. application/json).
  UTF-8 charset assumed.
  """
  @type media_type :: String.t()
  @type decoder :: (body :: binary() -> return(term()))
  @type option :: {:decode, {media_type, decoder}}
  @type opts :: [option]

  @typep resource :: Resource.t()
  @typep method :: Resource.method()
  @typep url :: Resource.url()
  @typep headers :: Resource.headers()

  @typep response :: Response.t()

  @callback do_request(method, url, headers) :: return

  @spec request(resource, opts) :: return
  def request(resource, opts \\ []), do: request(@adapter, resource, opts)

  @spec request(module(), resource, opts) :: return
  def request(adapter, resource, opts) do
    {method, url, headers} = Resource.request(resource)

    case adapter.do_request(method, url, headers) do
      {:ok, response} -> process_response(response, opts)
      {:error, _} = error -> error
    end
  end

  @spec process_response(response, opts) :: return
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
      {:ok, {_, _} = value} -> media_type_error(unsupported: value)
      {:error, error} -> media_type_error(error)
    end
  end

  defp media_type_error(info), do: {:error, Error.MediaType.exception(info)}
end
