defmodule HackerNews.Repo.TableOwner do
  @moduledoc """
  Module to interact with ETS tables and GenServer processes owning them.
  """

  use GenServer, restart: :temporary

  alias __MODULE__.State
  alias HackerNews.{Repo, RepoSupervisor}

  @spec create_tables([map()]) :: DynamicSupervisor.on_start_child()
  def create_tables(stories) do
    child_spec = {__MODULE__, stories: stories}
    # It may be appropriate to trigger GC on the repo process after
    # creation if we are sending a very big payload on init.
    DynamicSupervisor.start_child(RepoSupervisor, child_spec)
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
    {stories, opts} = Keyword.split(opts, [:stories])
    init_arg = Keyword.merge(stories, weight: weight_fn.())
    GenServer.start_link(__MODULE__, init_arg, opts)
  end

  @spec stop(pid()) :: :ok
  def stop(pid), do: GenServer.stop(pid)

  ### CALLBACKS

  defmodule State do
    @moduledoc false

    @enforce_keys [:weight]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            weight: pos_integer()
          }
  end

  @impl true
  def init(opts) do
    {stories, opts} = Keyword.pop!(opts, :stories)
    next = {:save, stories}
    {:ok, struct!(State, opts), {:continue, next}}
  end

  @tab_pages Repo.Pages
  @tab_stories Repo.Stories
  @read_concurrency {:read_concurrency, true}

  @impl true
  def handle_continue({:save, stories}, state) do
    tab_pages = :ets.new(@tab_pages, [:ordered_set, @read_concurrency])
    tab_stories = :ets.new(@tab_stories, [:set, @read_concurrency])

    _ =
      Enum.scan(stories, 1, fn story, key ->
        :ets.insert(tab_pages, {key, story})
        :ets.insert(tab_stories, {story["id"], key})
        key + 1
      end)

    tables = %{pages: tab_pages, stories: tab_stories}
    {:ok, _} = register(tables, state.weight)
    {:noreply, state}
  end

  defp register(%{} = tables, weight) do
    key = __MODULE__
    Registry.register(Registry.Tables, key, {weight, tables})
  end
end
