defmodule HackerNewsApi.Client.FinchAdapter do
  @moduledoc """
  `HackerNewsApi.Client` implementation for `Finch`.
  """

  alias HackerNewsApi.Client

  @behaviour Client

  @impl Client
  def do_request(method, url, headers) do
    request = Finch.build(method, url, headers)

    case Finch.request(request, :finch) do
      {:ok, response} -> transform(response)
      {:error, _} = error -> error
    end
  end

  @spec transform(Finch.Response.t()) :: Client.Response.t()
  defp transform(response) do
    response
    |> Map.take([:status, :headers])
    |> Map.put(:raw_body, response.body)
    |> Client.Response.new()
  end
end
