defmodule HackerNewsWeb.StoryView do
  use HackerNewsWeb, :view

  defp render_template("collection", stories) do
    %{
      items: stories,
      items_number: length(stories),
      more: nil
    }
  end
end
