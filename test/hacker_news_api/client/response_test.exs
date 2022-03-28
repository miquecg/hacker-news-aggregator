defmodule HackerNewsApi.Client.ResponseTest do
  use ExUnit.Case, async: true

  alias HackerNewsApi.Client.Response

  describe "get_media_type/1" do
    test "returns type/subtype and charset" do
      response =
        Response.new!(
          status: 200,
          headers: [
            {"Content-Type", "application/json; charset=UTF-8"},
            {"Content-Length", 280}
          ]
        )

      assert {:ok, {"application/json", "utf-8"}} = Response.get_media_type(response)
    end
  end
end
