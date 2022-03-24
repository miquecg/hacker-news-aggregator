defmodule HackerNewsApi.Client.Response do
  @moduledoc """
  Struct that represents an HTTP response.
  """

  defstruct [:status, :headers, :raw_body, :body]

  @type header :: {name :: String.t(), value :: String.t()}

  @type t :: %__MODULE__{
          status: 100..599,
          headers: [header],
          raw_body: binary(),
          body: term()
        }
end
