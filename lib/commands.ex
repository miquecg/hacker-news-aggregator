defmodule HackerNews.Commands do
  @moduledoc """
  High-level API for operating the app.
  """

  @spec update_stories :: :ok
  def update_stories do
    %{stories: stories, errors: errors} = HackerNews.fetch_top()
    :ok = HackerNews.store(stories)
    :ok = log_errors(errors)
  end

  defp log_errors(_errors), do: :ok
end
