defmodule HackerNews.RouterTest do
  use HackerNews.ConnCase, async: true

  test "get /stories returns json" do
    conn = conn(:get, "/stories")

    conn = Router.call(conn, @opts)
    stories = json_response(conn, 200)

    assert stories["items_number"] == 1
    assert stories["more"] == nil

    [story] = stories["items"]
    assert story["id"] == 8863
  end

  test "route not found" do
    conn = conn(:get, "/not-found")

    conn = Router.call(conn, @opts)

    assert conn.status == 404
  end
end
