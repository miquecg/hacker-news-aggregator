defmodule HackerNews.ConnCase do
  @moduledoc """
  Test case and helpers for tests that require a connection.
  """

  use ExUnit.CaseTemplate

  alias Plug.Conn

  using do
    fixture = Path.expand("stories.json", __DIR__)

    json_data =
      fixture
      |> File.read!()
      |> Jason.decode!()

    quote do
      import HackerNews.ConnCase
      import Plug.Conn
      import Plug.Test

      alias HackerNews.Repo
      alias HackerNewsWeb.Router

      @opts Router.init([])

      @external_resource unquote(fixture)
      def stories, do: unquote(Macro.escape(json_data))
    end
  end

  def json_response(conn, status) do
    body = response(conn, status)
    _ = response_content_type(conn)

    Jason.decode!(body)
  end

  defp response(conn, status) do
    :sent = conn.state
    200 = Conn.Status.code(status)
    conn.resp_body
  end

  defp response_content_type(conn) do
    [header] = Conn.get_resp_header(conn, "content-type")
    {:ok, "application", "json", _} = Conn.Utils.content_type(header)
  end
end
