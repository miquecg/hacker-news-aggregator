defmodule HackerNews.WebsocketCase do
  @moduledoc """
  Test case and helpers for tests that require a WebSocket.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import HackerNews.WebsocketCase
    end
  end

  setup do
    # Hardcoded server and port for the moment.
    {:ok, conn} = Mint.HTTP.connect(:http, "localhost", 4001)

    # Request connection be upgraded to the WebSocket protocol.
    {:ok, conn, ref} = Mint.WebSocket.upgrade(:ws, conn, "/ws", [])
    response = receive(do: (message -> message))

    {:ok, conn,
     [
       {:status, ^ref, status},
       {:headers, ^ref, headers},
       {:done, ^ref}
     ]} = Mint.WebSocket.stream(conn, response)

    {:ok, conn, websocket} = Mint.WebSocket.new(conn, ref, status, headers)

    %{conn: conn, ref: ref, websocket: websocket}
  end

  def decode(%{conn: conn, ref: ref, websocket: websocket}, message) do
    {:ok, _conn, [{:data, ^ref, data}]} = Mint.WebSocket.stream(conn, message)
    {:ok, _websocket, [{:text, json}]} = Mint.WebSocket.decode(websocket, data)
    Jason.decode!(json)
  end
end
