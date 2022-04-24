defmodule HackerNews.Repo.TableOwner do
  @moduledoc """
  Module to interact with ETS tables and GenServer processes owning them.
  """

  use GenServer, restart: :temporary

  alias __MODULE__.State
  alias HackerNews.{Repo, RepoSupervisor}

  @typep story :: map() | {non_neg_integer(), map()}

  @spec create_tables([story]) :: {:ok, pid()}
  def create_tables(stories) do
    # It may be appropriate to trigger GC on repo after tables creation.
    {:ok, repo} = DynamicSupervisor.start_child(RepoSupervisor, __MODULE__)
    :ok = GenServer.call(repo, {:save, index(stories)})
    {:ok, repo}
  end

  defp index([{_, %{}} | _] = stories), do: stories

  defp index(stories) do
    Enum.with_index(stories, fn %{} = story, index -> {index, story} end)
  end

  @typep tables :: %{pages: :ets.tid(), stories: :ets.tid()}

  @spec get_tables :: {:ok, tables} | {:error, :no_tables}
  def get_tables do
    all = Registry.lookup(Registry.Tables, __MODULE__)

    case sort_by_weight_desc(all) do
      [{_pid, {_weight, tables}} | _] -> {:ok, tables}
      [] -> {:error, :no_tables}
    end
  end

  @typep key :: pid()
  @typep value :: {weight :: pos_integer(), tables}

  @spec sort_by_weight_desc(all) :: all when all: [{key, value}]
  defp sort_by_weight_desc(tables) do
    Enum.sort_by(tables, fn {_pid, weighted_tables} -> weighted_tables end, :desc)
  end

  @spec get_tables(pid()) :: {:ok, tables} | {:error, :no_tables}
  def get_tables(owner) when is_pid(owner) do
    all = Registry.lookup(Registry.Tables, __MODULE__)
    found = for {^owner, {_weight, tables}} <- all, do: tables

    case found do
      [tables] -> {:ok, tables}
      [] -> {:error, :no_tables}
    end
  end

  @typep weight_fn :: (() -> pos_integer())
  @typep options :: GenServer.options()
  @typep on_start :: GenServer.on_start()

  @spec start_link(weight_fn, options) :: on_start
  def start_link(weight_fn, opts) do
    GenServer.start_link(__MODULE__, weight_fn.(), opts)
  end

  @spec stop(pid(), timeout()) :: :ok
  def stop(pid, timeout \\ :infinity) do
    GenServer.stop(pid, :normal, timeout)
  end

  ### CALLBACKS

  defmodule State do
    @moduledoc false

    @enforce_keys [:weight]
    defstruct @enforce_keys ++ [active?: false]

    @type t :: %__MODULE__{
            active?: boolean(),
            weight: pos_integer()
          }
  end

  @impl true
  def init(weight) do
    {:ok, %State{weight: weight}}
  end

  @tab_pages Repo.Pages
  @tab_stories Repo.Stories
  @read_concurrency {:read_concurrency, true}

  @impl true
  def handle_call({:save, stories}, _from, state) when not state.active? do
    tab_pages = :ets.new(@tab_pages, [:ordered_set, @read_concurrency])
    tab_stories = :ets.new(@tab_stories, [:set, @read_concurrency])

    :ets.insert(tab_pages, stories)

    Enum.each(stories, fn {index, %{"id" => id}} ->
      :ets.insert(tab_stories, {id, index})
    end)

    tables = %{pages: tab_pages, stories: tab_stories}
    {:ok, _} = register(tables, state.weight)
    {:reply, :ok, %{state | active?: true}}
  end

  defp register(%{} = tables, weight) do
    key = __MODULE__
    Registry.register(Registry.Tables, key, {weight, tables})
  end
end
