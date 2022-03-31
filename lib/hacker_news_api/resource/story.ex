defmodule HackerNewsApi.Resource.Story do
  @moduledoc """
  Story.

  Implements `HackerNewsApi.Resource` protocol.
  """

  use HackerNewsApi.BaseResource, path: "/v0/item/:item.json"
end
