defmodule HackerNews.Router do
  @plug_init_mode Application.compile_env(:hacker_news, :plug_init_mode, :compile)

  use Plug.Router, init_mode: @plug_init_mode
  use Plug.ErrorHandler

  require EEx

  plug Plug.Logger
  plug :match
  plug :dispatch

  EEx.function_from_file(
    :defp,
    :application_json,
    "lib/templates/application.json.eex",
    [:stories]
  )

  get "/stories" do
    stories = HackerNews.get_top_stories()
    render_json(conn, stories)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp render_json(conn, stories) do
    data = application_json(stories)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, data)
  end
end
