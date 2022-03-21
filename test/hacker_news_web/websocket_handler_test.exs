defmodule HackerNewsWeb.WebsocketHandlerTest do
  use HackerNews.WebsocketCase, async: true

  test "websocket sends stories upon connection", context do
    receive do
      message ->
        assert [] = decode(context, message)
    end
  end
end
