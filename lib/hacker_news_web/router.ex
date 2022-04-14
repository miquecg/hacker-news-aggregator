defmodule HackerNewsWeb.Router do
  use HackerNewsWeb, :router
  use Plug.ErrorHandler

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/stories" do
    result = %{cursor: cursor} = HackerNews.get_stories()
    meta = [page: [current: 1, next: next_page(conn, {2, cursor})]]

    conn
    |> assign(:stories, result.stories)
    |> merge_assigns(meta)
    |> render("collection.json")
    |> send_resp()
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp next_page(conn, {_number, _cursor} = data) do
    signed =
      Plug.Crypto.sign(
        conn.secret_key_base,
        "next-page",
        data,
        max_age: 300
      )

    path = ["#{conn.request_path}", "?page=", "#{signed}"]
    url = ["#{conn.scheme}", "://", "#{conn.host}", ":", "#{conn.port}", path]
    IO.iodata_to_binary(url)
  end
end
