defmodule HackerNews.RepoTest do
  use ExUnit.Case, async: false

  alias HackerNews.Repo

  setup do
    stories = [
      %{"id" => 31_024_767},
      %{"id" => 31_024_127},
      %{"id" => 31_020_229},
      %{"id" => 31_019_778},
      %{"id" => 31_014_847},
      %{"id" => 31_021_652},
      %{"id" => 31_023_695},
      %{"id" => 30_992_719},
      %{"id" => 31_024_363},
      %{"id" => 31_024_458},
      %{"id" => 31_015_813},
      %{"id" => 31_023_909},
      %{"id" => 31_025_061}
    ]

    {:ok, pid} = Repo.save(stories)
    on_exit(fn -> Repo.stop(pid) end)
    [repo: pid]
  end

  describe "all/2" do
    test "returns all stories", context do
      stories = Repo.all(context.repo, [])

      assert length(stories) == 13
      assert [%{"id" => 31_024_767} | _] = stories
    end

    test "returns all stories in several chunks", context do
      {stories, :end_of_table, next} = Repo.all(context.repo, limit: 5)

      assert length(stories) == 5
      assert [%{"id" => 31_024_767} | _] = stories

      {stories, _prev, next} = Repo.all(context.repo, cursor: next)

      assert length(stories) == 5
      assert [%{"id" => 31_021_652} | _] = stories

      {stories, _prev, :end_of_table} = Repo.all(context.repo, cursor: next)

      assert length(stories) == 3
      assert [%{"id" => 31_015_813} | _] = stories
    end

    test "returns a chunk as big as the table", context do
      {stories, :end_of_table, :end_of_table} = Repo.all(context.repo, limit: 20)

      assert length(stories) == 13
      assert [%{"id" => 31_024_767} | _] = stories
    end

    test "cursors work when last result size matches limit", context do
      {stories, :end_of_table, out_of_bounds} = Repo.all(context.repo, limit: 13)

      assert length(stories) == 13

      {[], prev, :end_of_table} = Repo.all(context.repo, cursor: out_of_bounds)
      {stories, :end_of_table, :end_of_table} = Repo.all(context.repo, cursor: prev)

      assert length(stories) == 13
    end

    test "does not mix options", context do
      {_, _prev, next} = Repo.all(context.repo, limit: 5)
      {stories, _prev, _next} = Repo.all(context.repo, limit: 3, cursor: next)

      assert length(stories) == 5
    end
  end

  describe "get/2" do
    test "returns one story", context do
      assert [%{"id" => 31_024_767}] = Repo.get(context.repo, 31_024_767)
    end

    test "returns empty list when not found", context do
      assert [] = Repo.get(context.repo, 1)
      assert [] = Repo.get(context.repo, :foo)
    end
  end
end
