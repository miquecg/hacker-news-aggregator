defmodule HackerNews.ScheduledTask.UpdateStories do
  @moduledoc """
  Schedules a task to update stories.
  """

  alias HackerNews.{Commands, ScheduledTask.RepoCleanup}

  def child_spec(opts) do
    crontab = Keyword.fetch!(opts, :crontab)

    %{
      id: "update-stories",
      start: {SchedEx, :run_every, [&update/0, crontab]}
    }
  end

  defp update do
    :ok = Commands.update_stories()

    {:ok, _} =
      DynamicSupervisor.start_child(
        HackerNews.ScheduledTaskSupervisor,
        RepoCleanup
      )
  end
end
