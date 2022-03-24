defmodule HackerNews.Application do
  @moduledoc false

  use Application

  alias HackerNews.Repo
  alias HackerNewsWeb.{Router, WebsocketHandler}

  @impl true
  def start(_type, _args) do
    children = [
      {Repo, name: :stories},
      {Finch, name: :finch},
      {
        Plug.Cowboy,
        scheme: :http,
        plug: Router,
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
         {"/ws", WebsocketHandler, []},
         {:_, Plug.Cowboy.Handler, {Router, []}}
       ]}
    ]
  end

  defp port do
    port = System.get_env("PORT", "4001")
    String.to_integer(port)
  end
end
