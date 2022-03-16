defmodule HackerNews.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {
        Plug.Cowboy,
        scheme: :http,
        plug: HackerNews.Router,
        options: [
          dispatch: dispatch(),
          port: port()
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: HackerNews.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/ws", HackerNews.WebsocketHandler, []},
         {:_, Plug.Cowboy.Handler, {HackerNews.Router, []}}
       ]}
    ]
  end

  defp port do
    port = System.get_env("PORT", "4001")
    String.to_integer(port)
  end
end
