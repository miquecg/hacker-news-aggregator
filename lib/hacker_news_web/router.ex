defmodule HackerNewsWeb.Router do
  use HackerNewsWeb, :router
  use Plug.ErrorHandler

  alias HackerNewsWeb.ErrorView

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [],
    pass: []

  plug :match
  plug :verify_token
  plug :dispatch

  get "/stories" do
    result = get_stories(conn.assigns)

    conn
    |> merge_assigns(Keyword.new(result))
    |> render("collection.json")
    |> send_resp()
  end

  defp get_stories(%{cursor: cursor}), do: HackerNews.get_stories(cursor)
  defp get_stories(_), do: HackerNews.get_stories()

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp verify_token(%{path_info: ["stories"]} = conn, _opts) do
    with {:ok, token} <- Map.fetch(conn.query_params, "page"),
         {:ok, {page, cursor}} <- verify(conn.secret_key_base, token) do
      merge_assigns(conn, page: page, cursor: cursor)
    else
      {:error, error} ->
        conn
        |> put_status(400)
        |> send_error(error)
        |> halt()

      _ ->
        assign(conn, :page, 1)
    end
  end

  defp verify_token(conn, _opts), do: conn

  defp verify(key_base, token) do
    Plug.Crypto.verify(
      key_base,
      "pages",
      token,
      max_age: 300
    )
  end

  defp send_error(conn, :invalid), do: send_resp(conn, conn.status, "")

  defp send_error(conn, :expired) do
    conn
    |> assign(:message, "Page results expired")
    |> put_view(ErrorView)
    |> render("error.json")
    |> send_resp()
  end
end
