defmodule HackerNewsApi.Error.ResourceError do
  @moduledoc """
  Exception for errors when fetching a `t:HackerNewsApi.Resource.t()`
  """

  alias HackerNewsApi.{Client.Response, Resource}

  defexception [:resource, :response, :reason]

  @type t :: %__MODULE__{
          resource: Resource.t(),
          response: Response.t() | nil,
          reason: atom() | Exception.t()
        }

  @impl true
  def message(%{resource: %name{}} = exception) do
    """
    cannot fetch resource #{name}
    #{exception.reason}
    """
  end
end
