defmodule HackerNewsApi.Error.TooManyRequests do
  @moduledoc """
  Exception for Too Many Requests.
  """

  alias HackerNewsApi.Resource

  defexception [:resource]

  @type t :: %__MODULE__{
          resource: Resource.t()
        }

  @impl true
  def message(%{resource: resource}) do
    %name{} = resource
    {method, url, headers} = Resource.request(resource)

    """
    cannot fetch resource #{name}
    Too Many Requests
    method: #{method}
    url: #{url}
    headers: #{inspect(headers)}
    """
  end
end
