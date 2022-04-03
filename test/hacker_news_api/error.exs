defmodule HackerNewsApi.ErrorTest do
  use ExUnit.Case, async: true

  alias HackerNewsApi.{Error, Resource.Story}

  require Error.Params

  test "raise Error.Params" do
    error =
      Error.Params.build(:some_error,
        param_1: "foo",
        param_2: %{a: 1},
        opts: [do_something: true]
      )

    assert_raise Error.Params, fn ->
      raise error
    end
  end

  test "raise Error.TooManyRequests" do
    error = %Error.TooManyRequests{resource: %Story{}}

    assert_raise Error.TooManyRequests, fn ->
      raise error
    end
  end

  test "raise Error.MediaType" do
    assert_raise Error.MediaType, fn ->
      raise Error.MediaType, unsupported: {"application/xml", "utf-16"}
    end

    assert_raise Error.MediaType, fn ->
      raise Error.MediaType, :missing
    end

    assert_raise Error.MediaType, fn ->
      raise Error.MediaType, :not_media_type
    end
  end
end
