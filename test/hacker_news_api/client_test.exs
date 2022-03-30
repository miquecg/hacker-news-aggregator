defmodule HackerNewsApi.ClientTest do
  use ExUnit.Case, async: true

  import Plug.Conn

  alias HackerNewsApi.{Client, Client.Response, Resource.TopStories}

  setup do
    bypass = Bypass.open()
    path = TopStories.path()
    url = "http://localhost:#{bypass.port}/#{path}"

    [bypass: bypass, resource: %TopStories{url: url}]
  end

  @top_stories [
    30_779_046,
    30_778_692,
    30_778_100,
    30_778_778,
    30_778_240,
    30_778_662
  ]

  test "fetch and decode Top Stories", context do
    Bypass.expect_once(context.bypass, "GET", "/v0/topstories.json", fn conn ->
      put_json_response(conn, @top_stories)
    end)

    opts = [option(:decode)]

    assert {:ok, %Response{body: @top_stories}} = Client.request(context.resource, opts)
  end

  test "decoder returns error", context do
    Bypass.expect_once(context.bypass, "GET", "/v0/topstories.json", fn conn ->
      put_json_response(conn, @top_stories)
    end)

    opts = [option(:decode, {:error, %Jason.DecodeError{}})]

    assert {:error, %Jason.DecodeError{}} = Client.request(context.resource, opts)
  end

  defp put_json_response(conn, data) do
    body = Jason.encode_to_iodata!(data)

    conn
    |> put_resp_content_type("application/json")
    |> resp(200, body)
  end

  defp option(:decode), do: option(:decode, &Jason.decode/1)

  defp option(:decode, decoder) when is_function(decoder) do
    {:decode, {"application/json", decoder}}
  end

  defp option(:decode, value), do: option(:decode, fn _ -> value end)
end
