defmodule HackerNewsWeb.StoryView do
  def render("collection.json", stories) do
    Jason.encode_to_iodata!(%{
      items: stories,
      items_number: length(stories),
      more: nil
    })
  end
end
