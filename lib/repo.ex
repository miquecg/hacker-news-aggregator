defmodule HackerNews.Repo do
  @moduledoc """
  Access to application data storage.
  """

  alias HackerNews.Repo.TableOwner

  @spec get(pos_integer()) :: [map()]
  def get(id), do: select({:id, id})

  @spec get(pid(), pos_integer()) :: [map()]
  def get(repo, id), do: select(repo, {:id, id})

  @opaque continuation :: {tuple(), limit :: pos_integer()}

  @type cursor :: continuation | :end_of_table

  @type query ::
          {:limit, pos_integer()}
          | {:cursor, cursor}
  @type query_opts :: [query]

  @type query_result :: [map()] | {[map()], prev :: cursor, next :: cursor}

  @spec all(query_opts) :: query_result
  def all(opts) do
    query = get_query(opts)
    select(query)
  end

  @spec all(pid(), query_opts) :: query_result
  def all(repo, opts) do
    query = get_query(opts)
    select(repo, query)
  end

  defp get_query(opts) do
    {:ok, opts} = Keyword.validate(opts, [:cursor, :limit])
    option(opts, :cursor) || option(opts, :limit) || :all
  end

  defp option(opts, key), do: List.keyfind(opts, key, 0)

  defp select(repo \\ nil, query)

  defp select(_, {:cursor, :end_of_table}), do: []

  defp select(_, {:cursor, {{:match, table, indexes}, limit}}) do
    do_select(table, {:cursor, {{:match, indexes}, limit}})
  end

  defp select(repo, query) when is_pid(repo) do
    case TableOwner.get_tables(repo) do
      {:ok, tables} -> do_select(tables, query)
      {:error, :no_tables} -> []
    end
  end

  defp select(_, query) do
    case TableOwner.get_tables() do
      {:ok, tables} -> do_select(tables, query)
      {:error, :no_tables} -> []
    end
  end

  @select [{:"$1", [], [:"$1"]}]

  defp do_select(tables, {:id, id}) do
    with [{_, key}] <- :ets.lookup(tables.stories, id),
         [{_, story}] <- :ets.lookup(tables.pages, key) do
      [story]
    end
  end

  defp do_select(%{pages: pages}, query), do: do_select(pages, query)

  defp do_select(table, :all) do
    stories = :ets.select(table, @select)
    drop_index(stories)
  end

  defp do_select(table, {:limit, limit}) do
    case :ets.select(table, @select, limit) do
      # Empty
      :"$end_of_table" -> {[], :end_of_table, :end_of_table}
      result -> process_result(table, result, limit)
    end
  end

  defp do_select(table, {:cursor, {{:match, indexes}, limit}}) do
    match_spec = for key <- indexes, do: {{key, :_}, [], [:"$_"]}
    {stories, _} = :ets.select(table, match_spec, limit)
    {prev, next} = create_cursors(table, stories, limit)
    {drop_index(stories), prev, next}
  end

  defp do_select(table, {:cursor, {continuation, limit}}) do
    # See: https://www.erlang.org/doc/man/ets.html#repair_continuation-2
    # Another approach for cursors: https://www.erlang.org/doc/man/qlc.html
    continuation = :ets.repair_continuation(continuation, @select)
    result = :ets.select(continuation)
    process_result(table, result, limit)
  end

  # Last result size matches limit so next
  # continuation is out of bounds.
  defp process_result(table, :"$end_of_table", limit) do
    last = :ets.last(table)
    {[], cursor_down(last, table, limit), :end_of_table}
  end

  defp process_result(table, {stories, :"$end_of_table"}, limit) do
    {prev, _} = create_cursors(table, stories, limit)
    {drop_index(stories), prev, :end_of_table}
  end

  defp process_result(table, {stories, continuation}, limit) do
    {prev, _} = create_cursors(table, stories, limit)
    next = {continuation, limit}
    {drop_index(stories), prev, next}
  end

  defp create_cursors(table, [{first, _} | _] = stories, limit) do
    prev = cursor_down(first - 1, table, limit)
    {last, _} = List.last(stories)
    next = cursor_up(last + 1, table, limit)
    {prev, next}
  end

  defp cursor_down(to, table, limit) when to >= 1 do
    from = max(to - limit + 1, 1)
    {{:match, table, from..to}, limit}
  end

  defp cursor_down(_, _, _), do: :end_of_table

  defp cursor_up(from, table, limit) do
    to = min(from + limit - 1, :ets.last(table))

    if from <= to do
      {{:match, table, from..to}, limit}
    else
      :end_of_table
    end
  end

  defp drop_index(stories), do: for({_pos, story} <- stories, do: story)

  @spec save([map()]) :: {:ok, pid()}
  def save(stories) do
    {:ok, _} = TableOwner.create_tables(stories)
  end

  defdelegate stop(pid), to: TableOwner
end
