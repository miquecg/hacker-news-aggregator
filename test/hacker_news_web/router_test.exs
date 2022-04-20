defmodule HackerNewsWeb.RouterTest do
  use HackerNews.ConnCase, async: true

  setup context do
    if context[:with_repo] do
      {:ok, pid} = Repo.save(stories())
      on_exit(fn -> Repo.stop(pid) end)
      [repo: pid]
    else
      :ok
    end
  end

  @tag :with_repo
  test "get /stories returns json" do
    conn = conn(:get, "/stories")

    conn = Router.call(conn, @opts)
    response = json_response(conn, 200)

    assert %{
             "items" => [story | _],
             "count" => 10,
             "meta" => %{
               "page" => 1,
               "next" => _,
               "prev" => nil
             }
           } = response

    assert story["id"] == 31_003_071
  end

  test "route not found" do
    conn = conn(:get, "/not-found")

    conn = Router.call(conn, @opts)

    assert conn.status == 404
  end
end
