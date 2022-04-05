defmodule HackerNewsApi.ErrorTest do
  use ExUnit.Case, async: true

  alias HackerNewsApi.{Error, Resource.Story}
  alias Error.{MediaTypeError, ParamsError}

  require ParamsError

  test "raise MediaTypeError" do
    assert_raise MediaTypeError, fn ->
      raise MediaTypeError, unsupported: {"application/xml", "utf-16"}
    end

    assert_raise MediaTypeError, fn ->
      raise MediaTypeError, :missing
    end

    assert_raise MediaTypeError, fn ->
      raise MediaTypeError, :not_media_type
    end
  end

  test "raise ParamsError" do
    error =
      ParamsError.build(:some_error,
        param_1: "foo",
        param_2: %{a: 1},
        opts: [do_something: true]
      )

    assert_raise ParamsError, fn ->
      raise error
    end
  end
end
