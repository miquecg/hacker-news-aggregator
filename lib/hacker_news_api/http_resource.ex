defprotocol HackerNewsApi.HttpResource do
  @moduledoc """
  Protocol that HTTP resources of the Hacker News API must implement.
  """

  @type url :: String.t()
  @type headers :: keyword()
  @type get :: {:get, url, headers}

  # Only GET requests at this moment.
  @type request :: get

  @doc """
  Must return a tuple representing one kind of `t:request/0`.
  """
  @spec request(t) :: request
  def request(resource)
end
