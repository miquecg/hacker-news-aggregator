defmodule HackerNewsWeb.StoryView do
  use HackerNewsWeb, :view

  defp render_template("collection", %{stories: stories, page: page}) do
    total = length(stories)

    %{
      items: stories,
      total: total,
      meta: %{
        page: page[:current],
        next: page[:next],
        prev: nil
      }
    }
  end
end
