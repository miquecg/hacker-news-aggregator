defmodule HackerNewsWeb.Router do
  use HackerNewsWeb, :router
  use Plug.ErrorHandler

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/stories" do
    stories = HackerNews.get_top_stories()

    conn
    |> render("collection.json", stories)
    |> send_resp()
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
