defmodule HackerNews.Commands do
  @moduledoc """
  High-level API for operating the app.
  """

  alias HackerNews.Repo.TableOwner
  alias HackerNewsWeb.WebsocketHandler

  @spec update_stories :: :ok
  def update_stories do
    %{stories: top_stories, errors: errors} = HackerNews.fetch_top()
    :ok = load_repo(top_stories)
    :ok = push_update(top_stories)
    :ok = log_errors(errors)
  end

  def load_repo([]), do: :ok

  def load_repo(new_stories) do
    {:ok, _} =
      case TableOwner.get_tables() do
        {:ok, %{pages: table}} ->
          all = merge_with(new_stories, table)
          TableOwner.create_tables(all)

        {:error, :no_tables} ->
          TableOwner.create_tables(new_stories)
      end

    :ok
  end

  defp merge_with(new_stories, table) do
    acc = map_with_index(new_stories)
    discard = discard_fn(new_stories)
    :ets.foldl(discard, acc, table)
  end

  defp map_with_index(new_stories) do
    {new_with_index, _} =
      Enum.reduce(new_stories, {[], 0}, fn story, {acc, index} ->
        {[{index, story} | acc], index + 1}
      end)

    new_with_index
  end

  defp discard_fn([%{"id" => first} | _] = stories) do
    {lookup_table, lowest_id} =
      Enum.reduce(stories, {%{}, first}, fn
        %{"id" => id}, {acc, lowest_id} ->
          {Map.put(acc, id, nil), min(lowest_id, id)}
      end)

    fn
      {_, %{"id" => id} = story}, acc when id < lowest_id ->
        prepend_with_index(story, acc)

      {_, %{"id" => id}}, acc when is_map_key(lookup_table, id) ->
        acc

      {_, story}, acc ->
        prepend_with_index(story, acc)
    end
  end

  defp prepend_with_index(story, [{last, _} | _] = acc) do
    [{last + 1, story} | acc]
  end

  def push_update(new_stories) do
    Registry.dispatch(
      Registry.Websockets,
      WebsocketHandler,
      &dispatch(&1, new_stories),
      parallel: true
    )
  end

  defp dispatch(entries, stories) do
    updated = for %{"id" => id} <- stories, do: id
    Enum.each(entries, fn {pid, past} -> send(pid, {:update, past, updated}) end)
  end

  def log_errors([]), do: :ok

  # For now just throw everything to stdout.
  def log_errors(errors) do
    IO.puts(inspect(errors))
    :ok
  end

  @spec remove_old_repos :: :ok | :none
  def remove_old_repos do
    all = Registry.lookup(Registry.Tables, TableOwner)
    remove_old_repos(all)
  end

  defp remove_old_repos([]), do: :none
  defp remove_old_repos([_]), do: :none

  defp remove_old_repos(all) do
    [_ | old] = Enum.sort_by(all, fn {_pid, tables} -> tables end, :desc)
    Enum.each(old, fn {pid, _} -> TableOwner.stop(pid, 2_000) end)
  end
end
