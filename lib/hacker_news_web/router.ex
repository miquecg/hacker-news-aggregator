defmodule HackerNewsWeb.Router do
  use HackerNewsWeb, :router
  use Plug.ErrorHandler

  alias HackerNewsWeb.ErrorView

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [],
    pass: []

  plug :match
  plug :validate_params
  plug :dispatch

  get "/stories" do
    result = get_stories(conn.assigns)

    conn
    |> merge_assigns(Keyword.new(result))
    |> render("collection.json")
    |> reply()
  end

  get "/stories/:id" do
    conn
    |> get_by()
    |> render_story()
    |> reply()
  end

  defp validate_params(%{path_info: ["stories"]} = conn, _opts) do
    with {:ok, token} <- Map.fetch(conn.query_params, "page"),
         {:ok, {page, cursor}} <- verify(conn.secret_key_base, token) do
      merge_assigns(conn, page: page, cursor: cursor)
    else
      {:error, error} ->
        conn
        |> send_error(error)
        |> halt()

      _ ->
        assign(conn, :page, 1)
    end
  end

  defp validate_params(%{path_info: ["stories", id]} = conn, _opts) do
    case Integer.parse(id) do
      {id, ""} ->
        assign(conn, :id, id)

      _ ->
        conn
        |> send_error(:invalid)
        |> halt()
    end
  end

  defp validate_params(conn, _opts), do: conn

  defp verify(key_base, token) do
    Plug.Crypto.verify(
      key_base,
      "pages",
      token,
      max_age: 300
    )
  end

  defp get_stories(%{cursor: cursor}), do: HackerNews.get_stories(cursor)
  defp get_stories(_), do: HackerNews.get_stories()

  defp get_by(conn) do
    if story = HackerNews.get_by(conn.assigns.id) do
      assign(conn, :story, story)
    else
      assign(conn, :error, :not_found)
    end
  end

  defp render_story(%{assigns: %{error: _}} = conn), do: conn
  defp render_story(conn), do: render(conn, "item.json")

  match _ do
    send_error(conn, :not_found)
  end

  defp reply(conn), do: reply(conn, conn.assigns)

  defp reply(conn, %{error: error}), do: send_error(conn, error)
  defp reply(conn, _), do: send_resp(conn)

  defp send_error(conn, :expired) do
    conn
    |> put_status(400)
    |> assign(:message, "Page results expired")
    |> put_view(ErrorView)
    |> render("error.json")
    |> send_resp()
  end

  defp send_error(conn, :invalid), do: send_resp(conn, 400, "")
  defp send_error(conn, :not_found), do: send_resp(conn, 404, "Not Found")
end
