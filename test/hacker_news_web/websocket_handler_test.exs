defmodule HackerNewsWeb.WebsocketHandlerTest do
  use HackerNews.WebsocketCase, async: false

  test "websocket sends stories upon connection", context do
    receive do
      message ->
        assert [%{"id" => 1}, _, _] = decode(context, message)
    end
  end
end
