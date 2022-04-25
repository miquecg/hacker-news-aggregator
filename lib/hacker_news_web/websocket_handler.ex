defmodule HackerNewsWeb.WebsocketHandler do
  @moduledoc """
  Handles WebSocket handshake and connection.
  """

  alias HackerNews.Repo

  @behaviour :cowboy_websocket

  @default_opts %{idle_timeout: :infinity}

  @impl :cowboy_websocket
  def init(request, []) do
    {:cowboy_websocket, request, [], @default_opts}
  end

  @impl :cowboy_websocket
  def websocket_init(state) do
    stories = get_stories()
    ids = for %{"id" => id} <- stories, do: id
    :ok = register_value(:sets.from_list(ids))
    commands = [{:active, false}] ++ reply(stories)
    {commands, state, :hibernate}
  end

  @impl :cowboy_websocket
  def websocket_handle(_, state) do
    {[], state}
  end

  @impl :cowboy_websocket
  def websocket_info({:update, past, updated}, state) do
    new = :sets.subtract(:sets.from_list(updated), past)
    :ok = update_value(past, new)
    {reply(new), state, :hibernate}
  end

  defp get_stories do
    case Repo.all(limit: 50) do
      {stories, _, _} -> stories
      [] -> []
    end
  end

  defp register_value(value) do
    {:ok, _} = Registry.register(Registry.Websockets, __MODULE__, value)
    :ok
  end

  defp update_value(past, new) do
    merged = :sets.union(past, new)
    :ok = Registry.unregister(Registry.Websockets, __MODULE__)
    register_value(merged)
  end

  defp reply([]), do: []

  defp reply([_ | _] = stories) do
    [{:text, Jason.encode_to_iodata!(stories)}]
  end

  defp reply(set) do
    stories = :sets.to_list(set)
    reply(stories)
  end
end
