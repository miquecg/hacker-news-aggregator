defmodule HackerNewsApi.Error.ResourceError do
  @moduledoc """
  Exception for errors with `t:HackerNewsApi.Resource.t()`
  """

  @enforce_keys [:reason, :resource]
  defexception [:response | @enforce_keys]

  alias HackerNewsApi.{Client.Response, Resource}

  @type t :: %__MODULE__{
          reason: Exception.t() | atom(),
          resource: Resource.t(),
          response: Response.t() | nil
        }

  @impl true
  def message(%{reason: reason}) when is_atom(reason), do: "#{reason}"

  @impl true
  def message(%{reason: reason}), do: Exception.message(reason)
end
