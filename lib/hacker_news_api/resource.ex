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
