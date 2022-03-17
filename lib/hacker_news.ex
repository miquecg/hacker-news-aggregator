defmodule HackerNews do
  @moduledoc """
  Service layer to encapsulate business logic.
  """

  alias HackerNews.Repo

  def get_top_stories, do: Repo.get_all(:stories)
end
