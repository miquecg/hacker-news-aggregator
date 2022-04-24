defmodule HackerNews.Application do
  @moduledoc false

  use Application

  alias HackerNews.RepoSupervisor
  alias HackerNews.ScheduledTask.UpdateStories
  alias HackerNewsWeb.{Router, WebsocketHandler}

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: Registry.Tables},
      RepoSupervisor,
      {Finch, name: :finch},
      {Task.Supervisor, name: HackerNewsApi.TaskSupervisor},
      {
        DynamicSupervisor,
        strategy: :one_for_one, name: HackerNews.ScheduledTaskSupervisor
      },
      {
        Registry,
        keys: :duplicate, name: Registry.Websockets, partitions: System.schedulers_online()
      },
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
    {:ok, pid} = Supervisor.start_link(children, opts)

    :ok = start_scheduled_tasks()

    {:ok, pid}
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

  defp start_scheduled_tasks do
    _ = if System.get_env("HN_FETCH"), do: update_stories()
    :ok
  end

  defp update_stories do
    {:ok, _} =
      DynamicSupervisor.start_child(
        HackerNews.ScheduledTaskSupervisor,
        # Every five minutes.
        {UpdateStories, crontab: "*/5 * * * *"}
      )
  end
end
