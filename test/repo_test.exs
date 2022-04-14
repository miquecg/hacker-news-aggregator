defmodule HackerNews.RepoTest do
  use ExUnit.Case, async: false

  alias HackerNews.Repo

  describe "all/2" do
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

    test "returns all stories", context do
      stories = Repo.all(context.repo, [])

      assert length(stories) == 13
      assert [%{"id" => 31_024_767} | _] = stories
    end

    test "returns chunks of five stories", context do
      {stories, continue} = Repo.all(context.repo, limit: 5)

      assert length(stories) == 5
      assert [%{"id" => 31_024_767} | _] = stories

      {stories, continue} = Repo.all(context.repo, continue: continue)

      assert length(stories) == 5
      assert [%{"id" => 31_021_652} | _] = stories

      {stories, continue} = Repo.all(context.repo, continue: continue)

      assert length(stories) == 3
      assert [%{"id" => 31_015_813} | _] = stories

      [] = Repo.all(context.repo, continue: continue)
    end

    test "returns a chunk as big as the table", context do
      {stories, continue} = Repo.all(context.repo, limit: 20)

      assert length(stories) == 13
      assert [%{"id" => 31_024_767} | _] = stories

      [] = Repo.all(context.repo, continue: continue)
    end

    test "does not mix options", context do
      {_, continue} = Repo.all(context.repo, limit: 5)
      {stories, _} = Repo.all(context.repo, limit: 3, continue: continue)

      assert length(stories) == 5
    end
  end
end
