defmodule HackerNews.Application do
  @moduledoc false

  use Application

  alias HackerNews.RepoSupervisor
  alias HackerNewsWeb.{Router, WebsocketHandler}

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: Registry.Tables},
      RepoSupervisor,
      {Finch, name: :finch},
      {Task.Supervisor, name: HackerNewsApi.TaskSupervisor},
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
    opts = Router.init([])

    [
      {:_,
       [
         {"/ws", WebsocketHandler, []},
         {:_, Plug.Cowboy.Handler, {Router, opts}}
       ]}
    ]
  end

  defp port do
    opts = Application.fetch_env!(:hacker_news, :web)
    Keyword.fetch!(opts, :port)
  end
end
