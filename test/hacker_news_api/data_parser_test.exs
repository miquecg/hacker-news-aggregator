defmodule HackerNewsApi.DataParserTest do
  use ExUnit.Case, async: true

  alias HackerNewsApi.DataParser, as: Parser

  describe "parse_url/2" do
    test "provides a default scheme" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("example.com", [])
      assert to_string(uri) == "https://example.com"

      assert {:ok, uri = %URI{}} = Parser.parse_url("localhost:4040", [])
      assert to_string(uri) == "https://localhost:4040"

      assert {:ok, uri = %URI{}} = Parser.parse_url("example.com", path: "/foo")
      assert to_string(uri) == "https://example.com/foo"
    end

    test "returns URL with given scheme" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("example.com", scheme: "http")
      assert to_string(uri) == "http://example.com"

      assert {:ok, uri = %URI{}} = Parser.parse_url("example.com/foo", scheme: "http")
      assert to_string(uri) == "http://example.com/foo"

      assert {:ok, uri = %URI{}} = Parser.parse_url("localhost:4040", scheme: "http")
      assert to_string(uri) == "http://localhost:4040"
    end

    test "returns URL with given path" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com", path: "/")
      assert to_string(uri) == "http://example.com/"

      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com", path: "/foo")
      assert to_string(uri) == "http://example.com/foo"

      assert {:ok, uri = %URI{}} = Parser.parse_url("localhost:4040", path: "/other")
      assert to_string(uri) == "https://localhost:4040/other"

      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com", path: "bar")
      assert to_string(uri) == "http://example.com/bar"

      assert {:ok, uri = %URI{}} = Parser.parse_url("localhost:4040", path: "baz")
      assert to_string(uri) == "https://localhost:4040/baz"
    end

    test "returns URL with given scheme and path" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("example.com", scheme: "http", path: "/foo")
      assert to_string(uri) == "http://example.com/foo"

      assert {:ok, uri = %URI{}} = Parser.parse_url("example.com", scheme: "http", path: "bar")
      assert to_string(uri) == "http://example.com/bar"
    end

    test "params are defaults and do not override" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/foo", scheme: "ftp")
      assert to_string(uri) == "http://example.com/foo"

      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/foo", path: "/bar")
      assert to_string(uri) == "http://example.com/foo"

      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/foo", path: "baz")
      assert to_string(uri) == "http://example.com/foo"
    end

    test "removes single forward slash" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/")
      assert to_string(uri) == "http://example.com"
    end

    test "removes double forward slashes" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/", path: "/foo")
      assert to_string(uri) == "http://example.com/foo"
    end

    test "returns error parsing URL without host" do
      assert {:error, :missing_host} = Parser.parse_url("http://", path: "/foo")
      assert {:error, :missing_host} = Parser.parse_url("http:///foo", [])
    end
  end

  describe "parse_path_params/1" do
    test "returns a list with all params in path" do
      assert {:ok, [":item"]} = Parser.parse_path_params("/stories/:item")
      assert {:ok, [":collection", ":item"]} = Parser.parse_path_params("/:collection/:item")
    end

    test "stops parsing param when reaching '.'" do
      assert {:ok, [":item"]} = Parser.parse_path_params("/stories/:item.json")
    end

    test "ignores strings not containing path delimiters" do
      assert {:ok, []} = Parser.parse_path_params("")
      assert {:ok, []} = Parser.parse_path_params("foo")
    end

    test "ignores double slashes" do
      assert {:ok, [":item"]} = Parser.parse_path_params("/stories//:item")
    end

    test "returns error with offending character for invalid param" do
      assert {:error, {"1tem", "1"}} = Parser.parse_path_params("/stories/:1tem")
    end
  end

  describe "parse_media_type/1" do
    test "returns type/subtype" do
      assert {:ok, {"application/json", nil}} = Parser.parse_media_type("application/json")
      assert {:ok, {"application/json", nil}} = Parser.parse_media_type("application/json;")
    end

    test "returns type/subtype and charset" do
      assert {:ok, {"application/json", "utf-8"}} =
               Parser.parse_media_type("application/json; charset=utf-8")

      assert {:ok, {"application/json", "utf-8"}} =
               Parser.parse_media_type("application/json; charset=utf-8 ; ")
    end

    test "ignores any other params" do
      assert {:ok, {"application/json", "utf-8"}} =
               Parser.parse_media_type(
                 "application/json; foo=bar ; charset=utf-8;encoding=utf-16"
               )
    end

    test "normalizes to lowercase" do
      assert {:ok, {"application/json", "utf-8"}} =
               Parser.parse_media_type("application/JSON; Charset=UTF-8")
    end
  end
end
