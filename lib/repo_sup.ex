defmodule HackerNews.RepoSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias HackerNews.Repo

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(
      max_children: 2,
      strategy: :one_for_one,
      extra_arguments: [create_counter()]
    )
  end

  defp create_counter do
    ref = :ets.new(Repo.Counter, [:public])
    :ets.insert(ref, {"weight", 0})
    fn -> :ets.update_counter(ref, "weight", 1) end
  end
end
