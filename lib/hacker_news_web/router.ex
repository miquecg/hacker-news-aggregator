defmodule HackerNewsWeb.Router do
  use HackerNewsWeb, :router
  use Plug.ErrorHandler

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/stories" do
    result = HackerNews.get_stories()
    view_data = Keyword.new(result)

    conn
    |> merge_assigns(view_data)
    |> render("collection.json")
    |> send_resp()
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
