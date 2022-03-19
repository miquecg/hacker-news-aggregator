defmodule HackerNews.Router do
  use HackerNewsWeb, :router
  use Plug.ErrorHandler

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/stories" do
    stories = HackerNews.get_top_stories()
    data = StoryView.render("collection.json", stories)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, data)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
