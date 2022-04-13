defmodule HackerNews.Repo do
  @moduledoc """
  Access to application data storage.
  """

  alias HackerNews.Repo.TableOwner

  @spec all :: [map()]
  def all do
    case TableOwner.get_tables() do
      {:ok, %{pages: pages}} -> select_all(pages)
      {:error, :no_tables} -> []
    end
  end

  @spec all(pid()) :: [map()]
  def all(repo) when is_pid(repo) do
    case TableOwner.get_tables(repo) do
      {:ok, %{pages: pages}} -> select_all(pages)
      {:error, :no_tables} -> []
    end
  end

  defp select_all(table), do: :ets.select(table, [{{:_, :"$1"}, [], [:"$1"]}])

  @spec save([map()]) :: {:ok, pid()}
  def save(stories) do
    tables = TableOwner.create_tables(stories)
    TableOwner.activate(tables)
  end

  defdelegate stop(pid), to: TableOwner
end
