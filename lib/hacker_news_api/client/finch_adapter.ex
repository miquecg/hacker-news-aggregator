defmodule HackerNewsApi.Client.FinchAdapter do
  @moduledoc """
  `HackerNewsApi.Client` implementation for `Finch`.
  """

  alias HackerNewsApi.{Client, Client.MediaTypeError, Resource}

  @behaviour Client

  @typep opts :: Client.opts()
  @typep acc :: map()
  @typep error :: {:error, Exception.t()}

  @impl Client
  def do_request(resource, opts \\ []) do
    {method, url, headers} = Resource.request(resource)
    request = Finch.build(method, url, headers)

    with {:ok, response} <- Finch.request(request, :finch),
         {:ok, response} <- process_response(response, opts) do
      {:ok, struct!(Client.Response, response)}
    end
  end

  @spec process_response(Finch.Response.t(), opts) :: Client.return()
  defp process_response(response, opts)

  defp process_response(response, opts) when response.status in 100..599 do
    acc = create_acc(response)

    opts
    |> Enum.reduce_while(acc, &process_with_option(response, &1, &2))
    |> result()
  end

  defp create_acc(response) do
    response
    |> Map.take([:status, :headers])
    |> Map.put(:raw_body, response.body)
  end

  defp process_with_option(response, {:decode, {media_type, decoder}}, acc) do
    with {"content-type", ^media_type} <- get_content_type(response.headers),
         {:ok, decoded} <- decoder.(response.body) do
      continue(put_in(acc[:body], decoded))
    else
      {"content-type", unsupported} -> media_type_error(unsupported)
      nil -> media_type_error(:missing)
      {:error, _} = error -> halt(error)
    end
  end

  defp process_with_option(_response, _option, acc), do: continue(acc)

  defp get_content_type(headers), do: List.keyfind(headers, "content-type", 0)

  @spec continue(acc) :: {:cont, acc}
  defp continue(acc), do: {:cont, acc}

  defp media_type_error(info) do
    error = {:error, MediaTypeError.exception(info)}
    halt(error)
  end

  @spec halt(error) :: {:halt, error}
  defp halt(error), do: {:halt, error}

  defp result({:error, _} = error), do: error
  defp result(%{} = result), do: {:ok, result}
end
