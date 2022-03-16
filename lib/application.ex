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
          port: 4001
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
end
