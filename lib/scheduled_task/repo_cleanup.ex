defmodule HackerNews.ScheduledTask.RepoCleanup do
  @moduledoc """
  Schedules a task to remove older repos.
  """

  require Logger

  alias HackerNews.Commands

  def child_spec(opts) do
    delay = Keyword.get(opts, :delay, 0)

    %{
      id: "repo-cleanup",
      start: {SchedEx, :run_in, [&cleanup/0, delay]},
      restart: :transient
    }
  end

  defp cleanup do
    case Commands.remove_old_repos() do
      :ok -> Logger.info("Old repos removed")
      :none -> Logger.info("No repos to cleanup")
    end
  end
end
