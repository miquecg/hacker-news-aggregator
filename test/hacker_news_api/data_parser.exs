defmodule HackerNewsApi.DataParserTest do
  use ExUnit.Case, async: true

  alias HackerNewsApi.DataParser, as: Parser

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

  test "returns URL with scheme appended" do
    assert {:ok, uri = %URI{}} = Parser.parse_url("example.com/foo", scheme: "http")
    assert to_string(uri) == "http://example.com/foo"
  end

  test "returns URL with path appended" do
    assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com", path: "/foo")
    assert to_string(uri) == "http://example.com/foo"

    assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com", path: "bar")
    assert to_string(uri) == "http://example.com/bar"
  end

  test "returns URL with scheme and path appended" do
    assert {:ok, uri = %URI{}} = Parser.parse_url("example.com", scheme: "http", path: "/foo")
    assert to_string(uri) == "http://example.com/foo"
  end

  test "params are defaults and do not override" do
    assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/foo", scheme: "ftp")
    assert to_string(uri) == "http://example.com/foo"

    assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/foo", path: "/bar")
    assert to_string(uri) == "http://example.com/foo"
  end

  test "double slashes are removed" do
    assert {:ok, uri = %URI{}} = Parser.parse_url("http://example.com/", path: "/foo")
    assert to_string(uri) == "http://example.com/foo"
  end
end
