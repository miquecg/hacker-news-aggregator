defmodule HackerNews.Router do
  @plug_init_mode Application.compile_env(:hacker_news, :plug_init_mode, :compile)

  use Plug.Router, init_mode: @plug_init_mode

  plug Plug.Logger
  plug :match
  plug :dispatch

  @response Jason.encode!(%{
              items: [
                %{
                  "by" => "dhouston",
                  "descendants" => 71,
                  "id" => 8863,
                  "kids" => [
                    8952,
                    9224,
                    8917,
                    8884,
                    8887
                  ],
                  "score" => 111,
                  "time" => 1_175_714_200,
                  "title" => "My YC app: Dropbox - Throw away your USB drive",
                  "type" => "story",
                  "url" => "http://www.getdropbox.com/u/2/screencast.html"
                }
              ],
              items_number: 1,
              more: nil
            })
  get "/stories" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, @response)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
