defmodule HackerNews.RouterTest do
  use HackerNews.ConnCase, async: true

  test "get /stories returns json" do
    conn = conn(:get, "/stories")

    conn = Router.call(conn, @opts)
    body = json_response(conn, 200)

    assert body["items_number"] == 1
    assert body["more"] == nil

    [story] = body["items"]
    assert story["id"] == 8863
  end
end
