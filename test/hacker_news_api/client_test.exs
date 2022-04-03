defmodule HackerNewsApi.ClientTest do
  use ExUnit.Case, async: true

  import Plug.Conn

  alias HackerNewsApi.{Client, Client.Response, Error, Resource.TopStories}

  setup do
    bypass = Bypass.open()
    path = TopStories.path()
    url = "http://localhost:#{bypass.port}/#{path}"

    [bypass: bypass, resource: %TopStories{url: url}]
  end

  @options [
    {:decode, {"application/json", &Jason.decode/1}},
    # Max. 4 retries
    # Min. delay 5 ms
    # Max. delay 10 ms
    {:retries, {4, 5, 10}}
  ]

  defp get_option(key), do: List.keyfind!(@options, key, 0)

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

    opts = [get_option(:decode)]

    assert {:ok, %Response{body: @top_stories}} = Client.request(context.resource, opts)
  end

  test "decoder returns error", context do
    Bypass.expect_once(context.bypass, "GET", "/v0/topstories.json", fn conn ->
      put_json_response(conn, @top_stories)
    end)

    decoder = fn _ -> {:error, %Jason.DecodeError{}} end
    opts = [{:decode, {"application/json", decoder}}]

    assert {:error, %Jason.DecodeError{}} = Client.request(context.resource, opts)
  end

  test "do not retry after one response status 429 (Too Many Requests)", context do
    Bypass.expect_once(context.bypass, "GET", "/v0/topstories.json", fn conn ->
      resp(conn, 429, "")
    end)

    opts = [{:retries, {0, 5, 10}}]

    assert {:error, %Error.TooManyRequests{}} = Client.request(context.resource, opts)
  end

  test "retry after one response status 429 (Too Many Requests)", context do
    # Need to do this little trick since Bypass do not support (yet)
    # setting multiple expectations for the same route.
    {:ok, agent} = Agent.start_link(fn -> 1 end)

    increment_fn = fn ->
      Agent.get_and_update(agent, fn step -> {step, step + 1} end)
    end

    Bypass.expect(context.bypass, "GET", "/v0/topstories.json", fn conn ->
      case increment_fn.() do
        # first attempt
        1 -> resp(conn, 429, "")
        # retry
        2 -> put_json_response(conn, @top_stories)
        _ -> flunk("Got more than one retry")
      end
    end)

    assert {:ok, %Response{body: @top_stories}} = Client.request(context.resource, @options)
  end

  defp put_json_response(conn, data) do
    body = Jason.encode_to_iodata!(data)

    conn
    |> put_resp_content_type("application/json")
    |> resp(200, body)
  end
end
