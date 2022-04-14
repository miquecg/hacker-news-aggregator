defmodule HackerNews.Repo.TableOwner do
  @moduledoc """
  Module to interact with ETS tables and GenServer processes owning them.
  """

  use GenServer, restart: :temporary

  alias __MODULE__.State
  alias HackerNews.{Repo, RepoSupervisor}

  @typep tables :: %{pages: :ets.tid(), stories: :ets.tid()}

  @tab_pages Repo.Pages
  @tab_stories Repo.Stories
  @read_concurrency {:read_concurrency, true}

  @spec create_tables([map()]) :: tables
  def create_tables(stories) do
    tab_pages = :ets.new(@tab_pages, [:ordered_set, @read_concurrency])
    tab_stories = :ets.new(@tab_stories, [:set, @read_concurrency])

    _ =
      Enum.reduce(stories, {1, 1}, fn story, {page, pos} ->
        key = {page, pos}
        :ets.insert(tab_pages, {key, story})
        :ets.insert(tab_stories, {story["id"], key})

        cond do
          pos < 10 -> {page, pos + 1}
          pos == 10 -> {page + 1, 1}
        end
      end)

    %{pages: tab_pages, stories: tab_stories}
  end

  @spec activate(tables) :: {:ok, pid()}
  def activate(tables) do
    return = {:ok, pid} = DynamicSupervisor.start_child(RepoSupervisor, __MODULE__)
    :ets.give_away(tables.pages, pid, @tab_pages)
    :ets.give_away(tables.stories, pid, @tab_stories)
    :ok = GenServer.call(pid, :register)
    return
  end

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

  @spec stop(pid()) :: :ok
  def stop(pid), do: GenServer.stop(pid)

  ### CALLBACKS

  defmodule State do
    @moduledoc false

    defstruct [:pages, :stories, :weight, active?: false]

    @type t :: %__MODULE__{
            active?: boolean(),
            pages: :ets.tid(),
            stories: :ets.tid(),
            weight: pos_integer()
          }
  end

  @impl true
  def init(weight) do
    {:ok, struct!(State, weight: weight)}
  end

  @impl true
  def handle_call(:register, _from, state) when state.active? do
    {:reply, {:error, :already_active}, state}
  end

  @impl true
  def handle_call(:register, _from, state) when not state.active? do
    key = __MODULE__
    weight = state.weight
    tables = Map.take(state, [:pages, :stories])
    {:ok, _} = Registry.register(Registry.Tables, key, {weight, tables})
    {:reply, :ok, %{state | active?: true}}
  end

  @impl true
  def handle_info({:"ETS-TRANSFER", ref, _from, @tab_pages}, %{pages: nil} = state) do
    {:noreply, %{state | pages: ref}}
  end

  @impl true
  def handle_info({:"ETS-TRANSFER", ref, _from, @tab_stories}, %{stories: nil} = state) do
    {:noreply, %{state | stories: ref}}
  end
end
