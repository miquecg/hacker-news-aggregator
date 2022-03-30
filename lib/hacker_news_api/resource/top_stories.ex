defmodule HackerNewsApi.Resource.TopStories do
  @moduledoc """
  Top stories.

  Implements `HackerNewsApi.Resource` protocol.
  """

  use HackerNewsApi.BaseResource, path: "/v0/topstories.json"
end
