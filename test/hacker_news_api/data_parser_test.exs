defmodule HackerNewsApi.DataParserTest do
  use ExUnit.Case, async: true

  alias HackerNewsApi.DataParser, as: Parser

  describe "parse_url/2" do
    test "returns error parsing URL without scheme" do
      assert {:error, :missing_scheme} = Parser.parse_url("", [])
      assert {:error, :missing_scheme} = Parser.parse_url("example.com", [])
      assert {:error, :missing_scheme} = Parser.parse_url("example.com", path: "/foo")
    end

    test "returns error parsing URL without path" do
      assert {:error, :missing_path} = Parser.parse_url("http://", [])
      assert {:error, :missing_path} = Parser.parse_url("http://example.com", [])
    end

    test "returns error parsing URL without host" do
      assert {:error, :missing_host} = Parser.parse_url("http://", path: "/foo")
      assert {:error, :missing_host} = Parser.parse_url("http:///foo", [])
    end

    test "returns URL with scheme" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("example.com/foo", scheme: "http")
      assert to_string(uri) == "http://example.com/foo"
    end

    test "returns URL with path" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com", path: "/foo")
      assert to_string(uri) == "http://example.com/foo"

      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com", path: "bar")
      assert to_string(uri) == "http://example.com/bar"
    end

    test "returns URL with scheme and path" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("example.com", scheme: "http", path: "/foo")
      assert to_string(uri) == "http://example.com/foo"
    end

    test "params are defaults and do not override" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/foo", scheme: "ftp")
      assert to_string(uri) == "http://example.com/foo"

      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/foo", path: "/bar")
      assert to_string(uri) == "http://example.com/foo"

      assert {:ok, uri = %URI{}} =
               Parser.parse_url("http://example.com:4040", scheme: "https", path: "bar")

      assert to_string(uri) == "http://example.com:4040/bar"
    end

    test "removes double slashes" do
      assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/", path: "/foo")
      assert to_string(uri) == "http://example.com/foo"
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
