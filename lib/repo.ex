defmodule HackerNews.Repo do
  @moduledoc """
  Access to application data storage.
  """

  alias HackerNews.Repo.TableOwner

  @opaque continuation :: :"$end_of_table" | tuple()

  @type query ::
          {:limit, pos_integer()}
          | {:continue, continuation}
  @type opts :: [query]

  @type query_result :: [map()] | {[map()], continuation}

  @spec all(opts) :: query_result
  def all(opts) do
    case TableOwner.get_tables() do
      {:ok, %{pages: pages}} -> select_all(pages, opts)
      {:error, :no_tables} -> []
    end
  end

  @spec all(pid(), opts) :: query_result
  def all(repo, opts) when is_pid(repo) do
    case TableOwner.get_tables(repo) do
      {:ok, %{pages: pages}} -> select_all(pages, opts)
      {:error, :no_tables} -> []
    end
  end

  defp select_all(table, opts) do
    query = get(opts, :continue) || get(opts, :limit) || :all
    select(table, query)
  end

  defp get(opts, key), do: List.keyfind(opts, key, 0)

  defp select(_table, {:continue, :"$end_of_table"}), do: []
  defp select(_table, {:continue, continuation}), do: :ets.select(continuation)

  defp select(table, {:limit, limit}) do
    :ets.select(table, [{{:_, :"$1"}, [], [:"$1"]}], limit)
  end

  defp select(table, :all) do
    :ets.select(table, [{{:_, :"$1"}, [], [:"$1"]}])
  end

  @spec save([map()]) :: {:ok, pid()}
  def save(stories) do
    tables = TableOwner.create_tables(stories)
    TableOwner.activate(tables)
  end

  defdelegate stop(pid), to: TableOwner
end
