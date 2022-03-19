defmodule HackerNewsWeb.WebsocketHandler do
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
    commands = [{:active, false}, {:text, "[]"}]
    {commands, state, :hibernate}
  end

  @impl :cowboy_websocket
  def websocket_handle(_, state) do
    {[], state}
  end

  @impl :cowboy_websocket
  def websocket_info(_, state) do
    {[], state}
  end
end
