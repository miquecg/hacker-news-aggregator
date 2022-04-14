defmodule HackerNews.RepoTest do
  use ExUnit.Case, async: false

  alias HackerNews.Repo

  describe "all/1" do
    setup do
      stories = [
        %{"id" => 324_566},
        %{"id" => 319_237}
      ]

      {:ok, pid} = Repo.save(stories)
      on_exit(fn -> Repo.stop(pid) end)
      [repo: pid]
    end

    test "without limit", context do
      assert [first, second] = Repo.all(context.repo)
      assert %{"id" => 324_566} = first
      assert %{"id" => 319_237} = second
    end
  end
end
