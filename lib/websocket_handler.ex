defmodule HackerNews.WebsocketHandler do
  @moduledoc """
  Handles WebSocket handshake and connection.
  """

  @behaviour :cowboy_websocket

  @impl :cowboy_websocket
  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  @impl :cowboy_websocket
  def websocket_init(state) do
    {[{:text, "ok"}], state}
  end

  @impl :cowboy_websocket
  def websocket_handle(_, state) do
    {[{:active, false}], state}
  end

  @impl :cowboy_websocket
  def websocket_info(_, state) do
    {[], state}
  end
end
