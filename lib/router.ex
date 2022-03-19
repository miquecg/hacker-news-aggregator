defmodule HackerNews.Router do
  use HackerNewsWeb, :router
  use Plug.ErrorHandler

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/stories" do
    stories = HackerNews.get_top_stories()
    render_json(conn, stories)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp render_json(conn, stories) do
    data = HackerNewsWeb.StoryView.render("collection.json", stories)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, data)
  end
end
